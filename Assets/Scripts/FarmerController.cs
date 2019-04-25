using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FarmerController : MonoBehaviour {
    public float speed = 10.0f;
    private float translation;
    private float straffe;
    private GameObject door;

	// Use this for initialization
	void Start () {
        Cursor.lockState = CursorLockMode.Locked;
        door = GameObject.Find("Door");
	}
	
	// Update is called once per frame
	void Update () {
        translation = Input.GetAxis("Vertical") * speed * Time.deltaTime;
        straffe = Input.GetAxis("Horizontal") * speed * Time.deltaTime;
        transform.Translate(straffe, 0, translation);

        if (Input.GetKeyDown("escape"))
        {
            Cursor.lockState = CursorLockMode.None;
        } else if (Input.GetKeyDown("f"))
        {
            print("yeah");
            if (Vector3.Distance(transform.position, door.transform.position) < 2f)
            {
                if (door.transform.rotation == Quaternion.Euler(0, 0, 0))
                {
                    door.transform.rotation = Quaternion.Euler(0, 90, 0);
                } else
                {
                    door.transform.rotation = Quaternion.Euler(0, 0, 0);
                }
            }
        }
    }
}
