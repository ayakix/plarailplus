#include <Arduino.h>
#include <SPI.h>
#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_SPI.h"
#include "Adafruit_BluefruitLE_UART.h"
#include "Adafruit_BLEGatt.h"

#include "BluefruitConfig.h"

#if SOFTWARE_SERIAL_AVAILABLE
  #include <SoftwareSerial.h>
#endif

Adafruit_BluefruitLE_SPI ble(BLUEFRUIT_SPI_CS, BLUEFRUIT_SPI_IRQ, BLUEFRUIT_SPI_RST);

Adafruit_BLEGatt gatt(ble);

void error(const __FlashStringHelper*err) {
  Serial.println(err);
  while (1);
}

int32_t serviceId;
int32_t characterId;

void setup(void) {
  Serial.begin(115200);
  Serial.println(F("Adafruit Bluefruit Device Information Service (DIS) Example"));
  Serial.println(F("---------------------------------------------------"));

  Serial.print(F("Initialising the Bluefruit LE module: "));

  if (!ble.begin(VERBOSE_MODE)) {
    error(F("Couldn't find Bluefruit, make sure it's in Command mode & check wiring?"));
  }
  Serial.println(F("OK!"));

  Serial.println(F("Performing a factory reset: "));
  if (!ble.factoryReset()){
       error(F("Couldn't factory reset"));
  }

  ble.echo(false);

  Serial.println(F("Setting device name to 'Bluefruit': "));
  if (!ble.sendCommandCheckOK(F("AT+GAPDEVNAME=Bluefruit"))) {
    error(F("Could not set device name?"));
  }

  boolean success;
  Serial.println(F("Adding the Custom Service: "));
  success = ble.sendCommandWithIntReply(F("AT+GATTADDSERVICE=UUID128=FF-02-AC-5B-32-A0-0C-DD-DB-39-5D-3A-B4-33-6C-6D"), &serviceId);
  if (!success) {
    error(F("Could not add Custom Service"));
  }

  // 0x02 : Read
  // 0x04 : Write without a response
  // 0x08 : Write with a response
  // 0x10 : Notifications
  Serial.println(F("Adding the Custom Characteristic: "));
  success = ble.sendCommandWithIntReply(F("AT+GATTADDCHAR=UUID128=FF-02-34-A7-32-A0-0C-DD-DB-39-5D-3A-B4-33-6C-6D,PROPERTIES=0x10,MIN_LEN=2, MAX_LEN=2, VALUE=00-00"), &characterId);
  if (!success) {
    error(F("Could not add Custom Characteristic"));
  }

  Serial.print(F("Adding Device Information Service UUID to the advertising payload: "));
  uint8_t advdata[] = {0x02, 0x01, 0x06, 0x05, 0x02, 0x09, 0x18, 0x0a, 0x18};
  ble.setAdvData(advdata, sizeof(advdata));
  ble.sendCommandCheckOK(F("AT+GAPSETADVDATA=02-01-06-05-02-0d-18-0a-18"));

  Serial.print(F("Performing a SW reset (service changes require a reset): "));
  ble.reset();

  Serial.println();
}

int lastValues[] = {0, 0};
uint8_t status[] = {0, 0};

void loop(void) {
  for (int i = 0; i < 2; i++) {
    int value = analogRead(i);
    if (lastValues[i] == 0 && value > 100) {
      status[i] = !status[i];
      gatt.setChar(characterId, status, 2);

      Serial.print(i);
      if (status[i]) {
        Serial.println(": ON");
      } else {
        Serial.println(": OFF");
      }
    }
    lastValues[i] = value;
    delay(50);
  }
}
