// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/MutTexture"
{
	Properties
	{
		_FrontTex("FrontTexture", 2D) = "white" {}
		_BackTex("BackTexture", 2D) = "white" {}
		_AlphaFront("AlphaFront",Range(0,1)) = 1
		_AlphaBack("AlphaBack",Range(0,1)) = 1
		_VerticalBillboarding("Verical Restranints",Range(0,1)) = 1
	}
	SubShader
	{
		//Tags { 
		//	"Queue"="Transparent"
		//	"IgoreProjector" ="True"
		//	"RenderType" = "Transparent"
		//	"DisableBatching" = "True"
		//	"LightMode" = "ForwardBase"
		//	}
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True" }
		LOD 100
			ZWrite Off
			Blend One OneMinusSrcAlpha
			Cull Off
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				UNITY_FOG_COORDS(1)
			};

			sampler2D _FrontTex;
			float4 _FrontTex_ST;
			sampler2D _BackTex;
			float4 _BackTex_ST;
			float _AlphaFront;
			float _AlphaBack;
			float _VerticalBillboarding;

			v2f vert (appdata v)
			{
				v2f o;
				// Suppose the center in object space is fixed
				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

				float3 normalDir = viewer - center;
				// If _VerticalBillboarding equals 1, we use the desired view dir as the normal dir
				// Which means the normal dir is fixed
				// Or if _VerticalBillboarding equals 0, the y of normal is 0
				// Which means the up dir is fixed
				normalDir.y = normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);
				// Get the approximate up dir
				// If normal dir is already towards up, then the up dir is towards front
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));

				// Use the three vectors to rotate the quad
				float3 centerOffs = v.vertex.xyz - center;
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
				o.vertex = mul(UNITY_MATRIX_MVP, float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord, _FrontTex);
				o.uv2 = TRANSFORM_TEX(v.texcoord, _BackTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				// sample the texture
				fixed4 col = tex2D(_FrontTex, i.uv);
				fixed4 colx = tex2D(_BackTex, i.uv2);
				colx.a *= _AlphaBack;
				fixed4 o = colx;
				col.rgb *= col.a*_AlphaFront;
				colx.rgb *= colx.a;
				o.rgb = colx.rgb+ col.rgb;
				return o;
			}
			ENDCG
		}
	}
}
