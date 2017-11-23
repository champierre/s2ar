using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HelpCloseButtonScript : MonoBehaviour {
	[SerializeField]
	GameObject panel;

	// Use this for initialization
	void Start () {
	}
	
	public void HelpButtonClosePressed() {
		panel.SetActive (false);
	}
}
