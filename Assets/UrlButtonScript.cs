using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UrlButtonScript : MonoBehaviour {

	// Use this for initialization
	void Start () {
		
	}
	
	public void UrlButtonPressed() {
		Application.OpenURL("https://github.com/champierre/s2ar");
	}
}
