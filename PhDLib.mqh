//+------------------------------------------------------------------+
//|                                                       PhDLib.mqh |
//|                    Copyright © 2018, Copyright 2018, PhD Systems |
//|                                     https://www.phdsystems.co.za |
//+------------------------------------------------------------------+
int CURRENT_TIMEFRAME      =  0; // Automatically picks up the TF where it is attached.
int CURRENT_BAR            =  0; // The current bar from where to count from when getting the indicator value

string convertTimeToString(int barIndex){
   return (string)iTime(Symbol(), CURRENT_TIMEFRAME, barIndex);
}

string convertCurrentTimeToString(){
   return (string)iTime(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);
}

datetime getCurrentTime(){
   return iTime(Symbol(), CURRENT_TIMEFRAME, 0);
}

double getPriceClose(int barIndex) {   
   return iClose(Symbol(), Period(), barIndex);
}

/**
 * This is just to avoid working with numeric directly
 */
int getPastBars(int barIndex){
   return (barIndex);
}

int getPreviousBarIndex(int barIndex){
   return (barIndex + 1);
}


double getPreviousPriceClose(int barIndex){
   return iClose(Symbol(), CURRENT_TIMEFRAME, barIndex);
}

/* START local enums */
enum StochasticsValues {
   SIGNAL_VALUE,
   STOCHASTIC_VALUE
};

enum Signal {
   BUY_SIGNAL,
   SELL_SIGNAL,
   NO_SIGNAL
};
string getSignalDescription(int signal) {
   
   switch(signal) {
   
      case 0: {
         
         return "BUY_SIGNAL";
      }
      
      case 1:{
         
         return "SELL_SIGNAL";
      }
   }
   return "NO_SIGNAL"; 
}

enum Zones {
   BULLISH_ZONE,
   BEARISH_ZONE,
   BULLISH_EXTREME_ZONE,
   BEARISH_EXTREME_ZONE,
   RANGING_ZONE,
   TRANSITION_ZONE,   
   NORMAL_ZONE,
   UNKNOWN_ZONE
};
string getZoneDescription(int zone) {
   
   switch(zone) {
   
      case 0: {
         
         return "BULLISH_ZONE";
      }
      
      case 1:{
         
         return "BEARISH_ZONE";
      }
      case 2:{
         
         return "BULLISH_EXTREME_ZONE";
      }
      case 3:{
         
         return "BEARISH_EXTREME_ZONE";
      }
      case 4:{
         
         return "RANGING_ZONE";
      }
      case 5:{
         
         return "TRANSITION_ZONE";
      }
      case 6:{
         
         return "NORMAL_ZONE";
      }  
      case 7:{
         
         return "UNKNOWN_ZONE";
      }                                  
   }
   return "NO_SIGNAL"; 
}

enum Sentiments {
   BULLISH,
   BEARISH
};

enum Cross {
   BULLISH_CROSS,
   BEARISH_CROSS,
   NO_CROSS,
   UNKNOWN_CROSS,
};

enum Reversal {
   BULLISH_REVERSAL,
   BEARISH_REVERSAL,
   CONTINUATION,
   UNKNOWN
};

enum Trend {
   BULLISH_TREND,
   BEARISH_TREND,
   BULLISH_SHORT_TERM_TREND,
   BEARISH_SHORT_TERM_TREND,
   NO_TREND
};

enum Slope {
   BULLISH_SLOPE,
   BEARISH_SLOPE,
   NEW_BULLISH_SLOPE,
   NEW_BEARISH_SLOPE,
   BULLISH_CONSOLIDATION_SLOPE,
   BEARISH_CONSOLIDATION_SLOPE,
   UNKNOWN_SLOPE //This should not happen
};

enum Flatter {
   BULLISH_FLATTER,
   BEARISH_FLATTER,
   NO_FLATTER
};

enum Transition {
   BULLISH_TO_BEARISH_TRANSITION,
   BEARISH_TO_BULLISH_TRANSITION,
   SUDDEN_BULLISH_TO_BEARISH_TRANSITION,
   SUDDEN_BEARISH_TO_BULLISH_TRANSITION,
   NO_TRANSITION
};

/* END local enums */