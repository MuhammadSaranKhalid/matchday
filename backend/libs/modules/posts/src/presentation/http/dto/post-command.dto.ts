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

const MAX_IMAGE_LONG_EDGE = 2_048;
const MAX_IMAGE_BYTES = 15_728_640;
const SUPPORTED_IMAGE_MIME = 'image/jpeg' as const;

export class PostMediaCommandDto {
  @IsInt()
  @Min(1)
  @Max(MAX_IMAGE_LONG_EDGE)
  width!: number;

  @IsInt()
  @Min(1)
  @Max(MAX_IMAGE_LONG_EDGE)
  height!: number;

  @IsInt()
  @Min(1)
  @Max(MAX_IMAGE_BYTES)
  bytes!: number;

  @IsEnum([SUPPORTED_IMAGE_MIME])
  mimeType!: typeof SUPPORTED_IMAGE_MIME;
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
