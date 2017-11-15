using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CubeMaker : MonoBehaviour {
	public GameObject cubePrefab;
	private Color _color;

	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	public void SetColor(Color color) {
		_color = color;
	}

	public void CreateCube(Vector3 atPosition) {
		GameObject cubeGO = Instantiate (cubePrefab, atPosition, Quaternion.identity);
		cubeGO.GetComponent<MeshRenderer>().material.SetColor("_Color", _color);
	}
}
