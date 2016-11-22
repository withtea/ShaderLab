Shader "Custom/UI/OutlineDefault"
{
    Properties
    {
		[PerRendererData]
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        _OutlineWidth("Outline Width", Float) = 2
        _Threshold("Threshold", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"
#include "UnityUI.cginc"

#pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
float4 vertex   :
                POSITION;
float4 color    :
                COLOR;
float2 texcoord :
                TEXCOORD0;
            };

            struct v2f
            {
float4 vertex   :
                SV_POSITION;
fixed4 color    :
                COLOR;
half2 texcoord  :
                TEXCOORD0;
float4 worldPosition :
                TEXCOORD1;
            };

            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                OUT.worldPosition = IN.vertex;
                OUT.vertex = mul(UNITY_MATRIX_MVP, OUT.worldPosition);

                OUT.texcoord = IN.texcoord;

#ifdef UNITY_HALF_TEXEL_OFFSET
                OUT.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
#endif

                OUT.color = IN.color * _Color;
                return OUT;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            float4 _OutlineColor;
            float _OutlineWidth;
            float _Threshold;

            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

#ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
#endif

                float width = _MainTex_TexelSize.z, height = _MainTex_TexelSize.w;

                if (color.a <= _Threshold)
                {
                    half2 dir[8] = { { 0,1 },{ 1,1 },{ 1,0 },{ 1,-1 },{ 0,-1 },{ -1,-1 },{ -1,0 },{ -1,1 } };
                    for (int i = 0; i < 8; i++)
                    {
                        float2 offset = float2(dir[i].x / width, dir[i].y / height);
                        offset *= _OutlineWidth;

                        half4 nearby = (tex2D(_MainTex, IN.texcoord + offset) + _TextureSampleAdd) * IN.color;
                        if (nearby.a > _Threshold)
                        {
                            color = _OutlineColor;
                            break;
                        }
                    }
                }

                return color;
            }
            ENDCG
        }
    }
}