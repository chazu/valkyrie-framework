{$INCLUDE valkyrie.inc}
unit vgltypes;
interface
uses Classes, SysUtils, vvector;

type
  TGLVec2f        = TVec2f;
  TGLVec3f        = TVec3f;
  TGLVec4f        = TVec4f;

  TGLVec2i        = TVec2i;
  TGLVec3i        = TVec3i;
  TGLVec4i        = TVec4i;

  TGLVec2b        = TVec2b;
  TGLVec3b        = TVec3b;
  TGLVec4b        = TVec4b;

  TGLRawQCoord    = specialize TGVectorQuad<TGLVec2i,Integer>;
  TGLRawQTexCoord = specialize TGVectorQuad<TGLVec2f,Single>;
  TGLRawQColor    = specialize TGVectorQuad<TGLVec3b,Byte>;
  TGLRawQColor4f  = specialize TGVectorQuad<TGLVec4f,Single>;

  PGLRawQCoord    = ^TGLRawQCoord;
  PGLRawQTexCoord = ^TGLRawQTexCoord;
  PGLRawQColor    = ^TGLRawQColor;

  TGLByteColor    = TGLVec3b;
  TGLFloatColor   = TGLVec3f;
  TGLFloatColor4  = TGLVec4f;


implementation

end.

