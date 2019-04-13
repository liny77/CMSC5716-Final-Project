Shader "ReaChan/Grass"
{
    Properties
    {
		[Header(Shading)]
		_TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		// grass size
		_BladeWidth("Blade Width", Float) = 0.05
		_BladeWidthRandom("Blade Width Random", Float) = 0.02
		_BladeHeight("Blade Height", Float) = 0.5
		_BladeHeightRandom("Blade Height Random", Float) = 0.3
		// tessellation
		_TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
		// winds
		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Float) = 1
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "CustomTessellation.cginc"

	// grass bend factor
	float _BendRotationRandom;
	// grass size factors
	float _BladeHeight;
	float _BladeHeightRandom;
	float _BladeWidth;
	float _BladeWidthRandom;

	// wind factors
	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrength;


	struct geometryOutput {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}


	geometryOutput toGeomOutput(float3 pos, float2 uv) {
		geometryOutput o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = uv;
		return o;
	}

	[maxvertexcount(3)]
	void geom(point vertexOutput IN[1], inout TriangleStream<geometryOutput> triStream) {
		float3 pos = IN[0].vertex;
		// compute tangent space vector
		float3 vNormal = IN[0].normal;
		float4 vTangent = IN[0].tangent;
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

		float3x3 TBN = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);
		// uv coordinates for winding and get value from wind texture
		float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
		// axis - wind direction
		float3 wind = normalize(float3(windSample.x, windSample.y, 0));
		// wind rotation matrix
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);
		// transformations for grass bend, shape, rotation(wind) and finally transform back from tangent space
		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
		float3x3 transformationMatrix = mul(mul(mul(TBN, windRotation), facingRotationMatrix), bendRotationMatrix);

		float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;

		triStream.Append(toGeomOutput(pos + mul(transformationMatrix, float3(width, 0.0, 0.0)), float2(0, 0)));
		triStream.Append(toGeomOutput(pos + mul(transformationMatrix, float3(-width, 0.0, 0.0)), float2(1, 0)));
		triStream.Append(toGeomOutput(pos + mul(transformationMatrix, float3(0.0, 0.0, height)), float2(0.5, 1)));
	}
	
	ENDCG


    SubShader
    {

		Cull Off

		Pass {
			Tags {
				"RenderType" = "Opaque" 
				"LightMode" = "ForwardBase"
			}
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6

			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;

			float4 frag(geometryOutput i, fixed facing : VFACE) : SV_Target
			{
				return lerp(_BottomColor, _TopColor, i.uv.y);
			}


			ENDCG
		}

        
    }
}
