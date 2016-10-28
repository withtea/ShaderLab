Shader "Hidden/BlendModesOverlay" {
	Properties {
		_MainTex ("Screen Blended", 2D) = "" {}
		_Overlay ("Color", 2D) = "grey" {}
		_Eliminatelay("Color", 2D) = "grey" {}
		_AlphaLay("Color", 2D) = "grey" {}
		_Noise("Color",2D) = "grey"{}
		_Back("Color",2D) = "grey"{}
	}
	
	CGINCLUDE

	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv[6] : TEXCOORD0;
	};
			
	sampler2D _Overlay;
	half4 _Overlay_ST;

	sampler2D _Eliminatelay;
	half4 _Eliminatelay_ST;

	sampler2D _MainTex;
	half4 _MainTex_ST;
	
	sampler2D _AlphaLay;
	half4 _AlphaLay_ST;

	sampler2D _Noise;
	half4 _Noise_ST;

	sampler2D _Back;
	half4 _Back_ST;

	half _Intensity;
	half4 _MainTex_TexelSize;
	half4 _UV_Transform = half4(1, 0, 0, 1);
		
	v2f vert( appdata_img v ) { 
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		
		o.uv[0] = UnityStereoScreenSpaceUVAdjust(float2(
			dot(v.texcoord.xy, _UV_Transform.xy),
			dot(v.texcoord.xy, _UV_Transform.zw)
		), _Overlay_ST);

		o.uv[2] = UnityStereoScreenSpaceUVAdjust(float2(
			dot(v.texcoord.xy, _UV_Transform.xy),
			dot(v.texcoord.xy, _UV_Transform.zw)
			), _Eliminatelay_ST);
		o.uv[3] = UnityStereoScreenSpaceUVAdjust(float2(
			dot(v.texcoord.xy, _UV_Transform.xy),
			dot(v.texcoord.xy, _UV_Transform.zw)
			), _AlphaLay_ST);
		o.uv[4] = UnityStereoScreenSpaceUVAdjust(float2(
			dot(v.texcoord.xy, _UV_Transform.xy),
			dot(v.texcoord.xy, _UV_Transform.zw)
			), _Noise_ST);
		o.uv[5] = UnityStereoScreenSpaceUVAdjust(float2(
			dot(v.texcoord.xy, _UV_Transform.xy),
			dot(v.texcoord.xy, _UV_Transform.zw)
			), _Back_ST);


		#if UNITY_UV_STARTS_AT_TOP
		if(_MainTex_TexelSize.y<0.0)
			o.uv[0].y = 1.0-o.uv[0].y;
		#endif
		
		o.uv[1] = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		return o;
	}
	
	half4 fragAddSub (v2f i) : SV_Target {
		half4 toAdd = tex2D(_Overlay, i.uv[0]) * _Intensity;
		return tex2D(_MainTex, i.uv[1]) + toAdd;
	}

	half4 fragMultiply (v2f i) : SV_Target {
		half4 toBlend = tex2D(_Overlay, i.uv[0]) * _Intensity;
		return tex2D(_MainTex, i.uv[1]) * toBlend;
	}	
			
	half4 fragScreen (v2f i) : SV_Target 
	{
		half4 toBlend =  (tex2D(_Overlay, i.uv[0]) * _Intensity);
		return 1-(1-toBlend)*(1-(tex2D(_MainTex, i.uv[1])));
	}

	half4 fragOverlay (v2f i) : SV_Target 
	{
		half4 m = (tex2D(_Overlay, i.uv[0]));
		half4 color = (tex2D(_MainTex, i.uv[1]));
		half4 eliminate = (tex2D(_Eliminatelay, i.uv[2]));
		half4 alpha = (tex2D(_AlphaLay, i.uv[3]));
		half4 noise = (tex2D(_Noise, i.uv[4]));
		half4 back = (tex2D(_Back, i.uv[5]));
		if ( color.r == eliminate.r && color.g == eliminate.g && color.b == eliminate.b )
		{
			return color;
		}
		float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
		color.rgb = half3(gray, gray, gray);
		color.rgb = color.rgb*noise.rgb;
		return half4(lerp(back.rgb, color.rgb, alpha.a), color.a);
	}
	
	half4 fragAlphaBlend (v2f i) : SV_Target {
		half4 toAdd = tex2D(_Overlay, i.uv[0]) ;
		return lerp(tex2D(_MainTex, i.uv[1]), toAdd, toAdd.a * _Intensity);
	}	


	ENDCG 
	
Subshader {
	  ZTest Always Cull Off ZWrite Off
      ColorMask RGB	  
  		  	
 Pass {    

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragAddSub
      ENDCG
  }

 Pass {    

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragScreen
      ENDCG
  }

 Pass {    

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragMultiply
      ENDCG
  }  

 Pass {    

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragOverlay
      ENDCG
  }  
  
 Pass {    

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragAlphaBlend
      ENDCG
  }   
}

Fallback off
	
} // shader
