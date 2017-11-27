using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SetOriginButtonScript : MonoBehaviour {
	[SerializeField]
	GameObject setOriginButton;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	public void SetOriginButtonPressed () {
		GameObject gameObject = GameObject.Find ("Origin");
		gameObject.GetComponent<UnityEngine.XR.iOS.UnityARHitTestExample> ().Unlock ();

		Button button = setOriginButton.GetComponent<Button> ();
		button.interactable = false;
	}
}
