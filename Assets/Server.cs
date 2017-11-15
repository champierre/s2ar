using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using WebSocketSharp;
using WebSocketSharp.Net;
using WebSocketSharp.Server;
using UnityEngine.UI;
using UnityEngine.XR.iOS;

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

		if (splitted [0] == "set_cube") {
			float x = float.Parse (splitted [1]);
			float y = float.Parse (splitted [2]);
			float z = float.Parse (splitted [3]);

			GameObject origin = GameObject.Find ("Origin") as GameObject;

			Vector3 atPosition = new Vector3 (x, y, z);

			GameObject cubeMaker = GameObject.Find ("CubeMaker") as GameObject;
			cubeMaker.SendMessage ("CreateCube", origin.transform.position + atPosition);
		} else if (splitted [0] == "set_color") {
			int r = int.Parse (splitted [1]);
			int g = int.Parse (splitted [2]);
			int b = int.Parse (splitted [3]);

			Color color = new Color (r / 255.0f, g / 255.0f, b / 255.0f);

			GameObject cubeMaker = GameObject.Find ("CubeMaker") as GameObject;
			cubeMaker.SendMessage ("SetColor", color);
		}

//		if (splitted[0] == "translate_x") {
//			float x = float.Parse(splitted[1]);
//			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
//			hitCube.transform.Translate (x, 0, 0);
//		} else if (splitted[0] == "translate_y") {
//			float y = float.Parse(splitted[1]);
//			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
//			hitCube.transform.Translate (0, y, 0);
//		} else if (splitted[0] == "translate_z") {
//			float z = float.Parse(splitted[1]);
//			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
//			hitCube.transform.Translate (0, 0, z);
//		}

	}
}
