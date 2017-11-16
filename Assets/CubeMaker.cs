using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CubeMaker : MonoBehaviour {
	public GameObject cubePrefab;
	private Color _color;
	private List<GameObject> cubes;

	// Use this for initialization
	void Start () {
		cubes = new List<GameObject>();
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
		cubes.Add (cubeGO);
	}

	public void Reset() {
		foreach (GameObject cubeGO in cubes){
			GameObject.Destroy(cubeGO);
		}
	}
}
