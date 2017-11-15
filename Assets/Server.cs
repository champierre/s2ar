using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using WebSocketSharp;
using WebSocketSharp.Net;
using WebSocketSharp.Server;
using UnityEngine.UI;

using System;
using System.Linq;

public class Server : MonoBehaviour {
	WebSocketServer server;

	// Use this for initialization
	void Start () {
		Debug.Log ("Start()");
		server = new WebSocketServer (3000);

		server.AddWebSocketService<Echo> ("/");
		server.Start ();
	}

	void OnDestroy() {
		server.Stop ();
		server = null;
	}

	// Update is called once per frame
	void Update () {
		
	}
}

public class Echo : WebSocketBehavior
{
	protected override void OnMessage(MessageEventArgs e)
	{
		Debug.Log ("OnMessage:" + e.Data);

		char[] separator = new char[] {':'};
		string[] splitted = e.Data.Split(separator);

		GameObject debugTextGO = GameObject.Find("DebugText") as GameObject;
		Text debugText = debugTextGO.GetComponent<Text> () as Text;
		debugText.text = e.Data;

		if (splitted[0] == "translate_x") {
			float x = float.Parse(splitted[1]);
			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
			hitCube.transform.Translate (x, 0, 0);
		} else if (splitted[0] == "translate_y") {
			float y = float.Parse(splitted[1]);
			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
			hitCube.transform.Translate (0, y, 0);
		} else if (splitted[0] == "translate_z") {
			float z = float.Parse(splitted[1]);
			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
			hitCube.transform.Translate (0, 0, z);
		}

//		Sessions.Broadcast(e.Data);
	}
}
