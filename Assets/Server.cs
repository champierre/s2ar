using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using WebSocketSharp;
using WebSocketSharp.Net;
using WebSocketSharp.Server;
using UnityEngine.UI;

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

		GameObject debugTextGO = GameObject.Find("DebugText") as GameObject;
		Text debugText = debugTextGO.GetComponent<Text> () as Text;
		debugText.text = e.Data;

		if (e.Data == "forward") {
			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
			hitCube.transform.Translate (0.1f, 0, 0);
		} else if (e.Data == "backward") {
			GameObject hitCube = GameObject.Find ("HitCube") as GameObject;
			hitCube.transform.Translate (-0.1f, 0, 0);
		}

		Sessions.Broadcast(e.Data);
	}
}
