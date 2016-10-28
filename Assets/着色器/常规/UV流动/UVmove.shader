Shader "Unlit/UVmove"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}
		_SecondTex ("SecondTex", 2D) = "white" {}
		_MainScollX("MainSpeed X",Float) = 0
		_SecondScollX("SecondSpeed X",Float) = 0
		_MainScollY("MainSpeed Y",Float) = 0
		_SecondScollY("SecondSpeed Y",Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SecondTex;
			float4 _SecondTex_ST;
			float _MainScollX;
			float _MainScollY;
			float _SecondScollX;
			float _SecondScollY;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex) + frac(float2(_MainScollX, _MainScollY)*_Time.y);
				o.uv.zw = TRANSFORM_TEX(v.uv, _SecondTex) + frac(float2(_SecondScollX, _SecondScollY)*_Time.y);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv.xy);
				fixed4 col_sc = tex2D(_SecondTex, i.uv.wz);
				col = lerp(col_sc, col, col.a);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
