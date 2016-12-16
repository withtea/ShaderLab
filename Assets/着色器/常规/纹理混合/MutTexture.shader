Shader "Unlit/MutTexture"
{
	Properties
	{
		_FrontTex("FrontTexture", 2D) = "white" {}
		_BackTex("BackTexture", 2D) = "white" {}
		_AlphaFront("AlphaFront",Range(0,1)) = 1
		_AlphaBack("AlphaBack",Range(0,1)) = 1
	}
	SubShader
	{
		Tags { 
			"RenderType"="Opaque"
			"RenderType" = "Transparent"
			}
		LOD 100
			ZWrite Off
			Blend One OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _FrontTex;
			float4 _FrontTex_ST;
			sampler2D _BackTex;
			float4 _BackTex_ST;
			float _AlphaFront;
			float _AlphaBack;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _FrontTex);
				o.uv2 = TRANSFORM_TEX(v.uv, _BackTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				// sample the texture
				fixed4 col = tex2D(_FrontTex, i.uv);
				fixed4 colx = tex2D(_BackTex, i.uv2);
				fixed4 o = col;
				col.rgb *= col.a*_AlphaFront;
				colx.rgb *= colx.a*_AlphaBack;
				o.rgb = colx.rgb+ col.rgb;
				o.rgb *= colx.a;
				return o;
			}
			ENDCG
		}
	}
}
