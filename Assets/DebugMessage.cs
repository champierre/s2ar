using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DebugMessage : MonoBehaviour {

	// Use this for initialization
	void Start () {
		Text debug = this.gameObject.GetComponent<Text> () as Text;
		debug.text = "IP Address:" + Network.player.ipAddress;
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
