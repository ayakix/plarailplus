#include "BLEDevice.h"
//#include "BLEScan.h"

#define DEVICE_CNT 2

#define HAYABUSA_PIN A0
#define KOMACHI_PIN A3

#define THRESHOLD 100

#define HAYABUSA_BLE_NAME "Scratch12445"
#define KOMACHI_BLE_NAME "Scratch12444"

// The remote service we wish to connect to.
static BLEUUID serviceUUID("7028FF00-0716-4982-A44C-F4961B5FC950");
// The characteristic of the remote service we are interested in.
static BLEUUID    charUUID("70283006-0716-4982-A44C-F4961B5FC950");

static boolean doConnect = false;
static boolean connected = false;
static boolean doScan = false;
static BLERemoteCharacteristic* pRemoteCharacteristics[DEVICE_CNT];
static BLEAdvertisedDevice* myDevices[DEVICE_CNT];
static int scannedCnt = 0;

static void notifyCallback(
  BLERemoteCharacteristic* pBLERemoteCharacteristic,
  uint8_t* pData,
  size_t length,
  bool isNotify) {
    Serial.print("Notify callback for characteristic ");
    Serial.print(pBLERemoteCharacteristic->getUUID().toString().c_str());
    Serial.print(" of data length ");
    Serial.println(length);
    Serial.print("data: ");
    Serial.println((char*)pData);
}

class MyClientCallback : public BLEClientCallbacks {
  void onConnect(BLEClient* pclient) {
    Serial.println("onConnected");
  }

  void onDisconnect(BLEClient* pclient) {
    connected = false;
    Serial.println("onDisconnect");
  }
};

bool connectToServer(int i) {
    Serial.print("Forming a connection to ");
    Serial.println(myDevices[i]->getAddress().toString().c_str());
    
    BLEClient*  pClient  = BLEDevice::createClient();
    Serial.println(" - Created client");
    
    pClient->setClientCallbacks(new MyClientCallback());
    
    // Connect to the remove BLE Server.
    pClient->connect(myDevices[i]);  // if you pass BLEAdvertisedDevice instead of address, it will be recognized type of peer device address (public or private)
    Serial.println(" - Connected to server");

    // Obtain a reference to the service we are after in the remote BLE server.
    BLERemoteService* pRemoteService = pClient->getService(serviceUUID);
    if (pRemoteService == nullptr) {
      Serial.print("Failed to find our service UUID: ");
      Serial.println(serviceUUID.toString().c_str());
      pClient->disconnect();
      return false;
    }
    Serial.println(" - Found our service");

    // Obtain a reference to the characteristic in the service of the remote BLE server.
    pRemoteCharacteristics[i] = pRemoteService->getCharacteristic(charUUID);
    if (pRemoteCharacteristics[i] == nullptr) {
      Serial.print("Failed to find our characteristic UUID: ");
      Serial.println(charUUID.toString().c_str());
      pClient->disconnect();
      return false;
    }
    Serial.println(" - Found our characteristic");

    // Read the value of the characteristic.
    if(pRemoteCharacteristics[i]->canRead()) {
      std::string value = pRemoteCharacteristics[i]->readValue();
      Serial.print("The characteristic value was: ");
      Serial.println(value.c_str());
    }

    if(pRemoteCharacteristics[i]->canNotify())
      pRemoteCharacteristics[i]->registerForNotify(notifyCallback);

    connected = true;
    return true;
}
/**
 * Scan for BLE servers and find the first one that advertises the service we are looking for.
 */
class MyAdvertisedDeviceCallbacks: public BLEAdvertisedDeviceCallbacks {
 /**
   * Called for each advertising BLE server.
   */
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    Serial.print("BLE Advertised Device found: ");
    Serial.println(advertisedDevice.toString().c_str());

    // We have found a device, let us now see if it contains the service we are looking for.
    if (advertisedDevice.haveServiceUUID() && advertisedDevice.isAdvertisingService(serviceUUID)) {
      if (scannedCnt < DEVICE_CNT) {
        myDevices[scannedCnt] = new BLEAdvertisedDevice(advertisedDevice);
        scannedCnt++;
      }
      
      if (scannedCnt >= DEVICE_CNT) {
        BLEDevice::getScan()->stop();
        doConnect = true;
        doScan = true;
      }
    } // Found our server
  } // onResult
}; // MyAdvertisedDeviceCallbacks


void setup() {
  Serial.begin(115200);
  Serial.println("Starting Arduino BLE Client application...");
  BLEDevice::init("");

  // Retrieve a Scanner and set the callback we want to use to be informed when we
  // have detected a new device.  Specify that we want active scanning and start the
  // scan to run for 5 seconds.
  BLEScan* pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setInterval(1349);
  pBLEScan->setWindow(449);
  pBLEScan->setActiveScan(true);
  pBLEScan->start(5, false);
} // End of setup.


int lastValues[] = {0, 0};
uint8_t status[] = {0, 0};

void loop() {
  // If the flag "doConnect" is true then we have scanned for and found the desired
  // BLE Server with which we wish to connect.  Now we connect to it.  Once we are 
  // connected we set the connected flag to be true.
  if (doConnect == true) {
    for (int i = 0; i < DEVICE_CNT; i++) {
      if (connectToServer(i)) {
        Serial.println("We are now connected to the BLE Server.");
      } else {
        Serial.println("We have failed to connect to the server; there is nothin more we will do.");
      }
      doConnect = false;
    }
  }
  
  // If we are connected to a peer BLE Server, update the characteristic each time we are reached
  // with the current time since boot.
  if (connected) {
    for (int i = 0; i < DEVICE_CNT; i++) {
      int pin = (myDevices[i]->getName() == HAYABUSA_BLE_NAME) ? HAYABUSA_PIN : KOMACHI_PIN;
      int value = analogRead(pin);
      if (lastValues[i] == 0 && value > THRESHOLD) {
        status[i] = !status[i];
        
        Serial.print(i);
        if (status[i]) {
          Serial.println(": ON");
          byte start[] = {0x01, 0x64, 0x00, 0x00, 0x00};
          pRemoteCharacteristics[i]->writeValue(start, 5);
        } else {
          Serial.println(": OFF");
          byte stop[] = {0x01, 0x00, 0x00, 0x00, 0x00};
          pRemoteCharacteristics[i]->writeValue(stop, 5);
        }
      }
      lastValues[i] = value;
      delay(50);
    }
    
  } else if(doScan){
    BLEDevice::getScan()->start(0);  // this is just eample to start scan after disconnect, most likely there is better way to do it in arduino
    delay(1000);
  }
} // End of loop
