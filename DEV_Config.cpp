/*****************************************************************************
* | File        :   DEV_Config.c
* | Author      :   Waveshare team
* | Function    :   Hardware underlying interface
* | Info        :
*                Used to shield the underlying layers of each master 
*                and enhance portability
*----------------
* | This version:   V1.0
* | Date        :   2018-11-22
* | Info        :

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documnetation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to  whom the Software is
# furished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS OR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
******************************************************************************/
#include "DEV_Config.h"

void GPIO_Init()
{
  pinMode(DEV_CS_PIN, OUTPUT);
  digitalWrite(DEV_CS_PIN, LOW);
  pinMode(DEV_RST_PIN, OUTPUT);
  pinMode(DEV_DC_PIN, OUTPUT);
  pinMode(DEV_BL_PIN, OUTPUT);
  analogWrite(DEV_BL_PIN,80);
 }
 void Config_Init()
 {

  GPIO_Init();
  
  //Serial
  Serial.begin(115200);
  Serial.println("\n[BOOT] Starting CoffeePot Monitor...");
  
  //spi
#if defined(ARDUINO_ARCH_ESP32)
  SPI.begin(DEV_SCK_PIN, -1, DEV_MOSI_PIN, DEV_CS_PIN);  // no MISO: the LCD is write-only
#else
  SPI.begin();
#endif
  // The LCD is the only SPI device, so this transaction is never ended
  SPI.beginTransaction(SPISettings(DEV_SPI_HZ, MSBFIRST, SPI_MODE3));
  }
