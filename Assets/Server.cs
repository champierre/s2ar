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
		server = new WebSocketServer (3000);
		server.AddWebSocketService<S2AR> ("/");
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

public class S2AR : WebSocketBehavior
{
	protected override void OnMessage(MessageEventArgs e)
	{
		char[] separator = new char[] {':'};
		string[] splitted = e.Data.Split(separator);

		GameObject debugGO = GameObject.Find("DebugMessage") as GameObject;
		Text debug = debugGO.GetComponent<Text> () as Text;
		debug.text = e.Data;

		GameObject cubeMaker = GameObject.Find ("CubeMaker") as GameObject;

		if (splitted[0] == "set_cube")
		{
			float x = float.Parse(splitted[1]) / 100.0f;
			float y = float.Parse(splitted[2]) / 100.0f;
			float z = float.Parse(splitted[3]) / 100.0f;

			GameObject origin = GameObject.Find("Origin") as GameObject;
			Vector3 atPosition = new Vector3(x, y, z);
			cubeMaker.SendMessage("CreateCube", origin.transform.position + atPosition);
		}
		else if (splitted[0] == "set_sphere")
		{
			int x = Int32.Parse(splitted[1]);
			int y = Int32.Parse(splitted[2]);
			int z = Int32.Parse(splitted[3]);
			int r = Int32.Parse(splitted[4]);

			GameObject origin = GameObject.Find("Origin") as GameObject;

			for (int k = -r; k <= r; k++)
			{
				for (int j = -r; j <= r; j++)
				{
					for (int i = -r; i <= r; i++)
					{
						if (i * i + j * j + k * k < r * r)
						{
							float fx = (x + i) / 100.0f;
							float fy = (y + j) / 100.0f;
							float fz = (z + k) / 100.0f;
							Vector3 atPosition = new Vector3(fx, fy, fz);
							cubeMaker.SendMessage("CreateCube", origin.transform.position + atPosition);
						}
					}
				}
			}
		}
		else if (splitted[0] == "set_color")
		{
			int r = int.Parse(splitted[1]);
			int g = int.Parse(splitted[2]);
			int b = int.Parse(splitted[3]);

			Color color = new Color(r / 255.0f, g / 255.0f, b / 255.0f);
			cubeMaker.SendMessage("SetColor", color);
		}
		else if (splitted[0] == "reset")
		{
			cubeMaker.SendMessage("Reset");
		}
		else if (splitted[0] == "connect")
		{
		}
	} 
}
