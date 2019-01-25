#include <CommandLine.h>

// ИК-приёмник
#define PIN_IR_RECIEVER 2
#include <iarduino_IR_RX.h>
iarduino_IR_RX IR(PIN_IR_RECIEVER);

// ИК-"пульт"
#define PIN_IR_SENDER 7
#include <iarduino_IR_TX.h>
iarduino_IR_TX VD(PIN_IR_SENDER); // Sender

// Показать полученные коды с пульта
bool irReciever = true;

// Работать как прокси, перенаправлять входящие коды на пульт
bool irProxy = true;

// Последний полученный код
long lastIrCode = 0;


// Коды с пульта SVEN
const int svenNum = 13;
struct keyStorage {
  const char *name[svenNum];
  long key[svenNum];
};

struct keyStorage svenKeys = {
  {"preset", "standby", "input", "sound", "mute", "sw+", "sw-", "c+", "c-", "s+", "s-", "m+", "m-"},
  {417804495, 417806535, 417802455, 417831015, 417798375, 417792255, 417826935, 417800415, 417835095, 417796335, 417839175, 417794295, 417837135}
};

void setup() {
  Serial.begin(9600);
  
  IR.begin();
  VD.begin();
  
  Serial.println("SvenRC is ready!");
}

void loop() {
  
  if(hasCommand()){
    const char *command = getCommand();
    
    // ir
    if (0 == strcmp(command, "ir")){
      char *irParam = getArg();
      if (0 == strcmp(irParam, "reciever")){
        irReciever = getArgInt() == 1;
        Serial.print("[IR] Reciever ");
        Serial.println((irReciever ? "enabled" : "disabled"));
      }     
      else if (0 == strcmp(irParam, "proxy")){
        irProxy = irReciever = getArgInt() == 1;
        Serial.print("[IR] Proxy "); 
        Serial.println((irProxy ? "enabled" : "disabled" ));
      }     
      else if (0 == strcmp(irParam, "send")){
        irSend(getArgInt());
      } else {
        Serial.println("[IR] Invalid command");
        Serial.print("ir reciever [1|0]   // Current: "); Serial.println((irReciever ? "enabled" : "disabled" ));
        Serial.print("ir proxy [1|0]   // Current: "); Serial.println((irProxy ? "enabled" : "disabled" ));
        Serial.println("ir send [long code]");
      }
    }

    // whoisit
    else if (0 == strcmp(command, "handshake")){
      Serial.println("<Arduino> SvenRC");
   }
    
    // sven
    else if (0 == strcmp(command, "sven")){
      sven(getArg());
    }

    // help
    else if (0 == strcmp(command, "help")){
         Serial.println("<<< Avaliable commands >>>");
         Serial.println("help - this command");
        // Serial.println("bluetooth [1|0]");
        // Serial.println("power [1|0]");
        // Serial.println("servo [get|set angle]");
         Serial.println("ir - get ir status");
         Serial.println("ir reciever [1|0]");
         Serial.println("ir proxy [1|0]");
         Serial.println("ir send [code]");
         Serial.println("sven [on|off]");
         Serial.println("sven [+|-] - increase or decrease volume");
         Serial.println("sven nobass");
         for(int i = 0; i < svenNum; ++i){
            Serial.print("sven "); Serial.println(svenKeys.name[i]);
        }
    }
    
    else {
       Serial.print("Undefined: "); 
       Serial.println(command);
    }
  }

   

  if(irReciever && IR.check(true)){
    lastIrCode = IR.data;    
    String s = "[IR] Recieve(";
    s.concat(IR.length);
    s.concat("): ");
    s.concat(lastIrCode);
    Serial.println(s);

    if(irProxy){
      irSend(lastIrCode);
    }
  }

  delay(500);
}

void irSend(long key){
  VD.send(key, true);
  Serial.print("[IR] Send "); 
  Serial.println(key);
}

void sven(const char *cmd){  
  if(strcmp("on", cmd) == 0){
    sven("standby");
    delay(1800);
    sven("input");
    delay(1800);
    sven("sound");
    return;
  }  
  else if(strcmp("off", cmd) == 0){
    sven("sound");
    delay(1800);
    sven("input");
    delay(1800);
    sven("standby");
    return;
  } else if(strcmp("+", cmd) == 0){
    for(int i = 0; i < 1; ++i){
      sven("sw+");
      sven("c+");
      sven("s+");
      sven("m+");
    }
    return;
  } else if(strcmp("-", cmd) == 0){
    for(int i = 0; i < 1; ++i){
      sven("sw-");
      sven("c-");
      sven("s-");
      sven("m-");
    }
    return;
  } else if(strcmp("nobass", cmd) == 0){
    for(int i = 0; i < 10; ++i){
      sven("sw-");
    }
    return;
  }
  
  for(int i = 0; i < svenNum; ++i){
    if(strcmp(svenKeys.name[i], cmd) == 0){
      for(int n = 0; n < 3; ++n){
        Serial.print("[Sven] ");
        Serial.print(svenKeys.name[i]);
        Serial.print(" < ");
        
        irSend(svenKeys.key[i]); 
        delay(60);
      } 
      return;
    }
  }

  Serial.print("Undefined: sven "); 
  Serial.println(cmd);
}
