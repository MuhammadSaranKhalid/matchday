import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { MEDIA_POLICY } from '../../../../../../modules/media/src/domain/media-policy.js';

export class PostMediaCommandDto {
  @IsInt()
  @Min(1)
  @Max(MEDIA_POLICY.source.maxLongEdge)
  width!: number;

  @IsInt()
  @Min(1)
  @Max(MEDIA_POLICY.source.maxLongEdge)
  height!: number;

  @IsInt()
  @Min(1)
  @Max(MEDIA_POLICY.source.maxBytes)
  bytes!: number;

  @IsEnum([MEDIA_POLICY.source.mimeType])
  mimeType!: 'image/jpeg';
}

export class CreatePostCommandDto {
  @IsUUID()
  clientCommandId!: string;

  @IsEnum(['user', 'team', 'tournament'])
  publisherType!: 'user' | 'team' | 'tournament';

  @IsUUID()
  publisherId!: string;

  @IsString()
  @MaxLength(64)
  postKind!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  text?: string;

  @IsArray()
  @ArrayMaxSize(4)
  @ValidateNested({ each: true })
  @Type(() => PostMediaCommandDto)
  media!: PostMediaCommandDto[];
}
