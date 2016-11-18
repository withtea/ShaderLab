Shader "UI/Unlit/RimFlashOnMask"
{
	Properties
	{
		[PerRendererData] 
		_MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1, 1, 1, 1)
		_Speed("Speed",Range(-50,50)) = 10
		_Angle("Angle",Range(0,1)) = 0.5
		_Intensity("Intensity",Range(0,10)) = 0.5
		_StartPos("StartPos",Range(0,1)) = 0.5
		_RimLightColor("Rim Light Color",Color) = (1,1,1,0)//高光颜色
		_Power("Power", float) = 1
		/* --------- */
		/* UI */
		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		/* -- */
	}
SubShader
{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}
		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		/* UI */
		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}
		/* -- */
	Pass
	{
				CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile _ PIXELSNAP_ON
#include "UnityCG.cginc"

		struct appdata_t
		{
			float4 vertex : POSITION;
			float4 color : COLOR;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			fixed4 color : COLOR;
			half2 texcoord : TEXCOORD0;
		};

		fixed4 _Color;

		/* Flowlight */
		float _Power;
		float _OffSet;
		fixed _Angle;
		half4 _RimLightColor;
		/* --------- */
		v2f vert(appdata_t IN)
		{
			v2f OUT;
			OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
			OUT.texcoord = IN.texcoord;
			OUT.color = IN.color * _Color;
		#ifdef PIXELSNAP_ON
			OUT.vertex = UnityPixelSnap(OUT.vertex);
		#endif
			return OUT;
		}

		sampler2D _MainTex;
		float4 _MainTex_ST;
		half4 _MainTex_TexelSize;
		float _Intensity;
		float _StartPos;
		float _AreaIntensity;
		float _Speed;
		fixed4 frag(v2f IN) : SV_Target
		{
			fixed4 c = tex2D(_MainTex, IN.texcoord)*IN.color;
			//坐标运算转为屏幕中心做二维坐标原点
			fixed2 TexOffset = _MainTex_TexelSize.xy;
			float2 uv = IN.texcoord - float2(0.5,0.5);
			// 遮罩角度  
			_Angle = 6.284 *((_Angle*_Time*_Speed)%1 - _StartPos);
			//反算出像素点角度的Tan值
			float TanAngle = atan2(uv.y,uv.x);
			//角度与高光角度的差距
			float AngleDis = 1 - saturate(abs(_Angle - TanAngle));
			AngleDis += 1 - saturate(abs(_Angle - TanAngle - 6.284));
			AngleDis += 1 - saturate(abs(_Angle - TanAngle + 6.284));
			//寻找图片的边缘值，即alpha的边缘
			fixed a0 = tex2D(_MainTex, IN.texcoord + TexOffset).a;
			fixed a1 = tex2D(_MainTex, IN.texcoord + TexOffset*fixed2(_Intensity,-_Intensity)).a;
			fixed a2 = tex2D(_MainTex, IN.texcoord + TexOffset*fixed2(-_Intensity, _Intensity)).a;
			fixed a3 = tex2D(_MainTex, IN.texcoord + TexOffset*fixed2(-_Intensity, -_Intensity)).a;
			fixed finala = abs(c.a*4 - (a0 + a1 + a2 + a3));
			AngleDis *= finala;
			// 打高光  
			float a = c.a;
			c = fixed4(_RimLightColor.rgb*AngleDis, 0)* _Power;
			c.rgb *= a;
			return c;
		}
		ENDCG
		}
	}
}