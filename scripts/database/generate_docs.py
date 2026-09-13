#!/usr/bin/env python3
"""Generate a metadata reference from a disposable Supabase migration replay.

--container NAME exports via docker/psql; --check verifies drift and generated pages.
Without arguments, regenerate pages from the checked-in snapshot (no database access).
Never run --container against a populated/deployed database: catalogue rows and
function definitions are included, although ordinary user rows are not queried.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from datetime import date

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'docs/database'
MIGRATIONS = ROOT / 'supabase/migrations'
GROUPS = {
 'identity': ('Identity and teams', 'profiles player_profiles unclaimed_players teams team_members team_member_roles team_invites team_join_requests claim_requests'),
 'authorization': ('Authorization catalogue', 'roles role_exclusion_sets role_exclusion_members permissions permission_scopes role_permissions grants'),
 'competition': ('Tournaments and venues', 'grounds tournaments tournament_grounds tournament_teams tournament_standings match_format_presets'),
 'matches': ('Matches and scoring', 'matches match_teams match_players match_innings match_innings_state match_deliveries match_wickets match_officials match_scorer_leases match_result_history match_challenges match_pool_applications'),
 'social': ('Posts and social activity', 'posts comments post_likes comment_likes bookmarks follows'),
 'messaging': ('Messaging', 'chats chat_members messages dm_channels'),
 'notifications': ('Notifications', 'notification_icons notification_categories notification_types notifications notification_preferences notification_mutes notification_deliveries device_tokens'),
}
PURPOSE = {
 'profiles':'Public-facing account identity linked to auth.users; onboarding, discoverability and account lifecycle.',
 'player_profiles':'Cricket-specific profile information attached to an account.',
 'unclaimed_players':'Players represented before they have an account; claiming links them to a registered identity.',
 'teams':'Team identity, presentation and configuration. created_by records history; ownership is a role assignment.',
 'team_members':'A person’s membership in a team, pointing to a registered or unclaimed player.',
 'team_member_roles':'Many-to-many assignments: one team member can hold multiple compatible roles.',
 'team_invites':'Invitations issued to registered users to join a team.',
 'team_join_requests':'Requests initiated by players to join a team; decision workflow is handled by RPCs.',
 'claim_requests':'Requests to claim an unregistered player identity and the resulting decision.',
 'roles':'Role definitions, display rank, singleton behavior and account requirements.',
 'role_exclusion_sets':'Limits on mutually restricted role combinations per member.',
 'role_exclusion_members':'Membership of roles in exclusion sets.',
 'permissions':'Named actions evaluated by the authorization engine.',
 'permission_scopes':'Valid entity scopes for each permission, shared by role rules and direct grants.',
 'role_permissions':'Default permission matrix plus per-team overrides; explicit denial is meaningful.',
 'grants':'Direct permission assignment on a scoped entity, subject to grantability and scope rules.',
 'grounds':'Reusable venue identity and geographic/search information.',
 'tournaments':'Competition configuration and lifecycle. Organizer authority still uses the tournament-specific model.',
 'tournament_grounds':'Links a tournament to its allowed venues.',
 'tournament_teams':'Registration/participation of a team in a tournament, including group and decision information.',
 'tournament_standings':'Persisted competition standings updated by result-processing workflows.',
 'match_format_presets':'Reusable format settings. A match stores its own format snapshot.',
 'matches':'Fixture, sides, start/toss phase, format snapshot and authoritative match result.',
 'match_teams':'Per-match side records; separate from reusable team identity.',
 'match_players':'Per-match lineup identities used by delivery and wicket references.',
 'match_innings':'Innings identity and lifecycle for a match.',
 'match_innings_state':'Hot innings snapshot, totals, batters/bowler and versioning, separate from fixture metadata.',
 'match_deliveries':'Ordered persisted scoring deliveries. Last-delivery undo is an intentional exception to append-oriented storage.',
 'match_wickets':'Dismissal detail associated with deliveries and match players.',
 'match_officials':'Match-level official assignments; scorer authorization is mirrored into scoped grants.',
 'match_scorer_leases':'Scorer lease state declared by the schema. Do not infer universal enforcement from the table alone.',
 'match_result_history':'Recorded result history, distinct from the current result on matches.',
 'match_challenges':'Direct/open friendly-match proposals, counteroffers, lineup choices and decision timers.',
 'match_pool_applications':'Teams applying to an open match; selected through application-decision RPCs.',
 'posts':'Content, context and linked entities, media metadata and denormalized engagement counters.',
 'comments':'Post comments and single-level replies, including mentions and edit state.',
 'post_likes':'Unique user/post reactions; triggers maintain counters and notify the post author.',
 'comment_likes':'Unique user/comment reactions; triggers maintain comment counters.',
 'bookmarks':'A user’s saved posts.',
 'follows':'Polymorphic social edges to a user, team or tournament. Notification mutes are stored separately.',
 'chats':'Conversation identity, including team and direct-message contexts.',
 'chat_members':'Per-user conversation membership, role and read/membership lifecycle.',
 'messages':'Persisted conversation messages and their lifecycle; Broadcast signals update clients.',
 'dm_channels':'Canonical user-pair mapping for direct-message conversations.',
 'notification_icons':'Admin-owned icon identity, immutable Storage path and upstream/license/checksum metadata.',
 'notification_categories':'Preference group names and ordering.',
 'notification_types':'Data-driven templates, routes, presentation, channels and coalescing rules.',
 'notifications':'Per-recipient rendered inbox snapshots, unread state and event-group revision.',
 'notification_preferences':'Sparse per-user/category/channel overrides; absence preserves catalogue defaults.',
 'notification_mutes':'Per-user scoped entity mutes and snoozes, including the follow bell.',
 'notification_deliveries':'Actual per-device/revision delivery outcomes. Queues own leases; this table does not.',
 'device_tokens':'Push destinations registered by the owning user; read by the trusted delivery worker.',
}

def manifest():
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(MIGRATIONS.glob('*.sql'))}

def source_links(name, kind='function'):
    regex = re.compile(r'create\s+(?:or\s+replace\s+)?'+kind+r'\s+(?:if\s+not\s+exists\s+)?(?:public\.)?'+re.escape(name)+r'\b',re.I)
    out=[]
    for p in sorted(MIGRATIONS.glob('*.sql')):
        if regex.search(p.read_text()): out.append(f'[{p.name}](../../supabase/migrations/{p.name})')
    return ', '.join(out) or 'See snapshot definition.'

def esc(x):
    if x is None:return '—'
    if isinstance(x,(dict,list)):x=json.dumps(x,ensure_ascii=False)
    return str(x).replace('|','\\|').replace('\n','<br>')

def table(headers, rows):
    return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+['| '+' | '.join(esc(x) for x in row)+' |' for row in rows])+'\n'

def render(snapshot):
    s=snapshot['catalog']; out={}; relations={r['name']:r for r in s['relations']}
    mapped=[n for _, names in GROUPS.values() for n in names.split()]
    actual={r['name'] for r in s['relations'] if r['kind'] in ('r','p')}
    if len(mapped)!=len(set(mapped)) or set(mapped)!=actual:
        raise SystemExit(f'Domain coverage mismatch: unmapped={actual-set(mapped)}, stale={set(mapped)-actual}')
    intro=f'> Generated from a disposable migration replay on {snapshot["captured_on"]}. PostgreSQL {s["postgres_version"]}. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.\n\n'
    for group,(title,names) in GROUPS.items():
        chunks=[f'# {title}: table reference\n',intro,'[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)\n']
        for name in names.split():
            r=relations[name]
            chunks += [f'## {name}\n',PURPOSE[name]+'\n',f'Canonical declaration: {source_links(name,"table")}\n',f'RLS enabled: **{r["rls"]}**. Forced RLS: **{r["force_rls"]}**. Table grants do not replace row policies.\n',
              table(['Column','PostgreSQL type','Nullable','Default / generated expression'],[(c['name'],c['type'],c['nullable'],('GENERATED: ' if c['generated'] else '')+(c['default'] or '—')) for c in r['columns']])]
            for c in r['columns']:
                if c['description']:chunks.append(f'- **{c["name"]}:** {c["description"]}\n')
            chunks += ['### Constraints\n',table(['Name','Definition','Deferrable / initially deferred'],[(c['name'],c['definition'],f'{c["deferrable"]} / {c["initially_deferred"]}') for c in r['constraints']]),
              '### Indexes\n',table(['Name','Definition'],[(i['name'],i['definition']) for i in r['indexes']]),
              '### Effective API grants\n',table(['Role','SELECT','INSERT','UPDATE table','DELETE','TRUNCATE','REFERENCES','TRIGGER'],[(g['role'],g['select'],g['insert'],g['update'],g['delete'],g['truncate'],g['references'],g['trigger']) for g in r['grants']])]
            narrow=[g for g in r['column_grants'] if not next((x[g['privilege'].lower()] for x in r['grants'] if x['role']==g['role']),False)]
            if narrow:chunks+=['Column-only grants (not implied by table-wide access):\n',table(['Role','Column','Privilege'],[(g['role'],g['column'],g['privilege']) for g in narrow])]
            chunks+=['### Row policies\n',table(['Policy','Command','Roles','USING','WITH CHECK'],[(p['policyname'],p['cmd'],p['roles'],p['qual'],p['with_check']) for p in r['policies']]),'### Triggers\n']
            chunks += [table(['Name','Definition'],[(t['name'],t['definition']) for t in r['triggers']]) if r['triggers'] else 'No non-system triggers attached.\n']
        out[f'tables-{group}.md']='\n'.join(chunks)
    chunks=['# Functions and compatibility views\n',intro,'[Handbook](README.md)\n',
      'This is the final replayed function set. Source links list declaration sites by name; overloaded signatures and later replacements must be compared against the signature and full definition in [schema-snapshot.json](schema-snapshot.json). EXECUTE permission alone is not business authorization. Trigger-returning functions cannot be invoked like ordinary RPCs.\n']
    for r in s['relations']:
        if r['kind'] in ('v','m'):chunks += [f'## View: {r["name"]}\n',f'Options: `{r["options"]}`. Source: {source_links(r["name"],"view")}\n',f'```sql\n{r["view_sql"]}\n```\n']
    for f in s['functions']:
        chunks += [f'## {f["name"]}\n',f'```sql\n{f["name"]}({f["arguments"]})\nRETURNS {f["returns"]}\n```\n',
        f'Language: **{f["language"]}**; security: **{"DEFINER" if f["security_definer"] else "INVOKER"}**; volatility: **{dict(i="immutable",s="stable",v="volatile")[f["volatility"]]}**; configuration: `{f["config"]}`.\n',
        'EXECUTE: '+', '.join(f'{k}={v}' for k,v in f['execute'].items())+'.\n',f'Source declarations: {source_links(f["name"])}\n']
        if f['description']:chunks.append(f['description']+'\n')
    out['routines.md']='\n'.join(chunks)
    chunks=['# Enumerations, catalogue data, and platform objects\n',intro,'[Handbook](README.md)\n','## PostgreSQL enums\n',
      'Enums are declared centrally in shared_helpers. Catalogue keys such as roles and notification types are rows, not enums. An enum defines possible values, not all allowed transitions.\n',
      table(['Enum','Values'],[(e['name'],', '.join(e['values'])) for e in s['enums']]),'## Installed extensions\n',table(['Extension','Version on replay','Schema'],[(e['name'],e['version'],e['schema']) for e in s['extensions']])]
    for name,rows in s['catalogues'].items():
        chunks += [f'## {name}\n','Seeded configuration from the empty replay. These are definitions, not user fixtures.\n']
        if rows:
            keys=list(rows[0]);chunks.append(table(keys,[[r.get(k) for k in keys] for r in rows]))
    chunks += ['## Storage buckets\n',table(['Bucket','Public','Maximum bytes','Allowed MIME types'],[(b['id'],b['public'],b['file_size_limit'],b['allowed_mime_types']) for b in s['buckets']])]
    for label,key in [('Storage policies','storage_policies'),('Realtime authorization policies','realtime_policies')]:
        chunks += [f'## {label}\n',table(['Table','Policy','Command','Roles','USING','WITH CHECK'],[(p['tablename'],p['policyname'],p['cmd'],p['roles'],p['qual'],p['with_check']) for p in s[key] or []])]
    chunks+=['## Scheduled jobs\n',table(['Name','Schedule','Active','Command'],[(j['name'],j['schedule'],j['active'],j['command']) for j in s['cron']]),'## Publication membership\n',table(['Publication','Table','Row filter'],[(p['pubname'],p['tablename'],p['rowfilter']) for p in s['publications'] or []])]
    out['catalogues.md']='\n'.join(chunks)
    chunks=['# Migration inventory\n',intro,'[Handbook](README.md) · [Rules and change workflow](migration-guide.md)\n',
      'Files are ordered lexically by their unique numeric prefix. A later CREATE OR REPLACE can supersede an earlier routine. The final hardening sweep must remain last. Hashes pin this inventory to the reviewed checkout.\n']
    rows=[]
    for name,digest in snapshot['migrations'].items():
        text=(MIGRATIONS/name).read_text()
        declared=[n for n in PURPOSE if re.search(r'create\s+table\s+(?:if\s+not\s+exists\s+)?public\.'+re.escape(n)+r'\b',text,re.I)]
        funcs=sorted(set(re.findall(r'create\s+(?:or\s+replace\s+)?function\s+public\.([a-z_0-9]+)',text,re.I)))
        rows.append((f'[{name}](../../supabase/migrations/{name})',', '.join(declared) or 'Integration / helpers',', '.join(funcs) or '—',digest[:12]))
    chunks.append(table(['Migration','Table declaration','Function declarations / replacements','SHA-256 prefix'],rows))
    out['migrations.md']='\n'.join(chunks)
    chunks=['# Foreign-key relationship diagrams\n',intro,'[Handbook](README.md)\n',
      'Each arrow is an actual foreign key in the replayed schema. Arrow direction is child → referenced parent. Labels identify child columns. These are dependency graphs, not claims that every parent has children or that every relationship is mandatory. Exact nullability, uniqueness, composite keys and ON DELETE actions are in the table reference. Dashed-looking logical relations are deliberately not invented for polymorphic UUIDs or UUID arrays. External/domain-crossing tables appear as reference nodes.\n']
    all_edges=[]
    for group,(title,names) in GROUPS.items():
        edges=[];nodes=set(names.split())
        for name in names.split():
            for c in relations[name]['constraints']:
                if c['type']=='f':
                    parent=c['foreign_table'].removeprefix('public.')
                    edge=(name,parent,', '.join(c['columns']));edges.append(edge);all_edges.append(edge);nodes.add(parent)
        lines=['flowchart LR']
        for n in sorted(nodes):lines.append(f'  {n.replace(".","_")}["{n}"]')
        for child,parent,col in edges:lines.append(f'  {child} -->|"{col}"| {parent.replace(".","_")}')
        graph='\n'.join(lines)+'\n';out[f'diagrams/{group}.mmd']=graph
        chunks += [f'## {title}\n',f'```mermaid\n{graph}```\n']
    graph='flowchart LR\n'
    nodes=sorted(set(x for e in all_edges for x in e[:2]))
    for n in nodes:graph+=f'  {n.replace(".","_")}["{n}"]\n'
    for c,p,col in all_edges:graph+=f'  {c} -->|"{col}"| {p.replace(".","_")}\n'
    out['diagrams/all-foreign-keys.mmd']=graph
    chunks+=['## Complete graph\n','[Editable Mermaid source for all foreign keys](diagrams/all-foreign-keys.mmd). Use the focused diagrams above for reading; the full graph is for impact tracing.\n',
      '## Relationships without foreign keys\n','`follows(target_type,target_id)`, `notification_mutes(scope,entity_id)`, notification entity references, and scoped grant entity IDs need discriminator-aware reasoning. JSON payloads, arrays and Storage paths are not automatically checked by a foreign key. Their validation/cleanup depends on constraints, triggers and application code; inspect those paths when adding a new scope.\n']
    out['relationships.md']='\n'.join(chunks)
    return out

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--container');p.add_argument('--check',action='store_true');args=p.parse_args()
    if args.container and args.check:p.error('Choose export or check')
    path=DEST/'schema-snapshot.json'
    if args.container:
        result=subprocess.run(['docker','exec','-i',args.container,'psql','-U','postgres','-XAt','-v','ON_ERROR_STOP=1'],input=(ROOT/'scripts/database/introspect.sql').read_text(),text=True,capture_output=True,check=True)
        snapshot={'captured_on':str(date.today()),'scope':'Disposable source replay; not hosted state','migrations':manifest(),'catalog':json.loads(result.stdout)}
        path.write_text(json.dumps(snapshot,indent=2,ensure_ascii=False)+'\n')
    else:snapshot=json.loads(path.read_text())
    if snapshot['migrations']!=manifest():raise SystemExit('Migration drift: replay migrations and export a new snapshot before regenerating.')
    outputs=render(snapshot);errors=[]
    for name,content in outputs.items():
        dest=DEST/name
        if args.check:
            if not dest.exists() or dest.read_text()!=content:errors.append(name)
        else:dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(content)
    if errors:raise SystemExit('Stale generated documents: '+', '.join(errors))
    print(f'{"Verified" if args.check else "Generated"} {len(outputs)} files; {len(snapshot["catalog"]["relations"])} relations, {len(snapshot["catalog"]["functions"])} functions, {len(snapshot["migrations"])} migrations.')

if __name__=='__main__':main()
