using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using WebSocketSharp;
using WebSocketSharp.Net;

public class ClientExample : MonoBehaviour {
	WebSocket ws;

	// Use this for initialization
	void Start () {
		ws = new WebSocket ("ws://localhost:3000/");

		ws.OnOpen += (sender, e) =>
		{
			Debug.Log("WebSocket Open");
		};

		ws.OnMessage += (sender, e) =>
		{
			Debug.Log("WebSocket Message Data: " + e.Data);
		};

		ws.OnError += (sender, e) =>
		{
			Debug.Log ("WebSocket Error Message: " + e.Message);
		};

		ws.OnClose += (sender, e) => {
			Debug.Log ("WebSocket Close");
		};

		ws.Connect();
	}

	
	// Update is called once per frame
	void Update () {

		if (Input.GetKeyUp ("s")) {
			ws.Send ("Test Message");
		}
		
	}

	void OnDestroy() {
		ws.Close ();
		ws = null;
	}
}
