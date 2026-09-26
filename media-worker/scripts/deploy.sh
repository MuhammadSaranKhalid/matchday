#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building TypeScript..."
npm run build

echo "Building Vercel prebuilt bundle..."
npx vercel build --prod

echo "Ensuring Linux Sharp platform packages exist..."
mkdir -p .platform-pkgs
if [ ! -d ".platform-pkgs/extracted/@img/sharp-linux-arm64" ]; then
  (
    cd .platform-pkgs
    npm pack @img/sharp-linux-arm64@0.33.5 @img/sharp-libvips-linux-arm64@1.0.4 @img/sharp-linux-x64@0.33.5 @img/sharp-libvips-linux-x64@1.0.4
    mkdir -p extracted/@img/sharp-linux-arm64 extracted/@img/sharp-libvips-linux-arm64 extracted/@img/sharp-linux-x64 extracted/@img/sharp-libvips-linux-x64
    tar -xzf img-sharp-linux-arm64-0.33.5.tgz -C extracted/@img/sharp-linux-arm64 --strip-components=1
    tar -xzf img-sharp-libvips-linux-arm64-1.0.4.tgz -C extracted/@img/sharp-libvips-linux-arm64 --strip-components=1
    tar -xzf img-sharp-linux-x64-0.33.5.tgz -C extracted/@img/sharp-linux-x64 --strip-components=1
    tar -xzf img-sharp-libvips-linux-x64-1.0.4.tgz -C extracted/@img/sharp-libvips-linux-x64 --strip-components=1
  )
fi

echo "Injecting Linux Sharp packages into Serverless Function bundle..."
cp -r .platform-pkgs/extracted/@img/* .vercel/output/functions/api/media-worker.func/node_modules/@img/

echo "Deploying prebuilt production bundle to Vercel..."
npx vercel deploy --prebuilt --prod

echo "Vercel media-worker deployment complete!"
