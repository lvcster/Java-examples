//+------------------------------------------------------------------+
//|                                                                  |   
//|   PhD Appsolute System                                           |
//|                                                                  |
//|   Copyright 2018, PhD Systems                                    |
//|   https://www.phdinvest.co.za                                    |
//|                                                                  |
//|   EA Based on SOMAT3 34,0.5; 30,0; 20,0 and IRC Triplets         |
//|                                                                  |
//|   Renamed from PhD Sometrig FX - 01/07/2018                      |
//|                                                                  |
//|   Notes: Reversal:                                              |
//|   Compares 2 bars, either (cur + prev) or (prev 1+prev2)         | 
//|                                                                  |
//|   TODO - Should be able test only current, current&prev, prev*2  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, PhD Systems"
#property link      "https://www.phdinvest.co.za"
#property version   "400.00" 


//TODOS
//1. Give reasons why trade is opened - high( which indicators triggered)
//2. Give reasons why trade is closed - high( which indicators triggered)

#property strict

//+------------------------------------------------------------------+
//| Utility functions                                                |
//+------------------------------------------------------------------+
#include <stdlib.mqh>
//#include <stderror.mqh>
//#include <WinUser32.mqh>

// General attributes
int CURRENT_TIMEFRAME      =  0; // Automatically picks up the TF where it is attached.
int CURRENT_BAR            =  0; // The current bar from where to count from when getting the indicator value
string SYMBOL              =  Symbol(); // Current symbol of the chart the EA applied on
ENUM_TIMEFRAMES TIMEFRAME  =  NULL; // Current time frame of the chart the EA applied on

// Trade transactions
int slippage            =  5;    // Acceptable price deviation
string buyComment       =  "Buy order trigered by the signal";  // Buy comment
string sellComment      =  "Sell order trigered by the signal"; // Sell comment
int BUY_MAGIC_NUMBER    =  1;    // Some random number
int SELL_MAGIC_NUMBER   =  2;    // Some random number
datetime ORDER_EXPIRATION_TIME =  0; 

// Position attributes
int retries = 5; //If  order fails to close, try several number of times to close   
int initialTrendSetUp = -1;     // Get trade setup based on the conditions
bool isInLongPosition;// true if in long position
bool isInShortPosition;// true if in short position
int orderType;
int magicNumber;
string comment;

//Open trade conditions
bool preConditionsMet;  /* 1. Buy or Sell must be setup,  2. if there's any open orders they must be closed succefully first  */


//Trade Management
bool breakEven = false; // Global variable to track if break even happened
//Track number of bars since trade opened
int barsMovedSinceOpenTrade               =  0;
int openTradeBarsTimer                    =  0;
datetime orderModifyTime                  =  0;

//--------TRADE SETUP ATTRIBUTES-----------
int previousTrade =  -1; 
extern string TRADE_SETUP_ATTRIBUTES;     //--------TRADE SETUP ATTRIBUTES----------
extern bool rideTrend                     =  false;
// Re-Enter after TP or SL(When conditions are met) on the same trend
extern bool reEnterOnNextSetup            =  true;  

//--------MONEY MANAGEMANT-----------------
// Money Management
bool isMoneyManagementEnabled             =  false;
bool alreadyModified                      =  false; 
int trailingStopPointsOnHAChangeColor     =  10;
extern string MONEY_MANAGEMANT;           //--------MONEY MANAGEMANT----------------
extern double lVolume                     =  0.02;
extern int trailingStopPoints             =  10;   
extern int targetPointsTrailingStop       =  20; 
extern int targetPointsBeforeTrailingStop =  20;
extern int initialStopPoints              =  10;
extern int breakEvenTargetPoints          =  30;
extern int initialTargetPoints            =  70;
extern bool applyBreakEven                =  true;
extern bool forceCloseOnOppositeSignal     =  true;

extern int period                         = 34;
extern double sensitivityFactor           = 1;
extern bool validatePreviousbar           = false;
extern bool autotradingEnabled            = false;
extern bool trendFilterEnabled            = false;

int DYNAMIC_MPA_METHOD = 15;

//Indicator constants
static string STEP_RSI         =  "-PhD StepRSI";                    
static string OCN_NMC_AND_MA   =  "-PhD OcnMa OffChart Boundries";  
static string IRC_TRIPPLETS    =  "-PhD IRC Tripplets";             
static string IRC_TRIPPLETS_V2 =  "-PhD IRC Tripplets v2";           
static string SOMAT3           =  "-PhD SOMAT3";                    
static string SOMA_LITE        =  "-PhD SOMA Lite";                    
static string STEPPED_MA       =  "-PhD Stepped MA";                 
static string MR_TRIGGER       =  "-PhD MR-Trigger";                 
static string TREND_SCORE      =  "-PhD TrendScore";                 
static string VELOCITY_STEPS   =  "-PhD Velocity Steps";             
static string SADUKI           =  "-PhD Saduki";                     
static string LEVEL_STOP       =  "-PhD Level Stop";                
static string WCCI             =  "-PhD wCCI";                      
static string TEST             =  "-velocity"; 
static string PERFECT_TREND    =  "-PhD Perfect Trend";              
static string QEPS             =  "-PhD Qeps";                      
static string QEVELO           =  "-PhD QeVelo";                    
static string DYNAMIC_STEEPPED_STOCH   =  "-PhD DySteppedStoch";            
static string DYNAMIC_NOLAG_MA         =  "-PhD DiNoLagMa"; //Multi time frame issues 
static string DYNAMIC_OF_AVERAGES      =  "-PhD DiZOA";
static string DYNAMIC_MPA              =  "-PhD DiMPA";
static string DYNAMIC_EFT              =  "-PhD DiEFT";
static string EFT                      =  "-PhD EFT";
static string DYNAMIC_WPR_OFF_CHART    =  "-PhD DiWPR offChart";
static string DYNAMIC_WPR_ON_CHART     =  "-PhD DiWPR onChart";
static string RSI_FILTER               =  "-rsi-filter";

//START BANDS
static string DYNAMIC_JURIK            =  "-PhD DiJurik";
static string MAIN_STOCH               =  "-PhD Main Stochastic";
static string DYNAMIC_MACD_RSI         =  "-PhD DiMcDRsi";
static string DYNAMIC_PRICE_ZONE       =  "-PhD DiPriceZone";
static string STOCHASTIC               =  "-PhD Stochastic v.2";
static string CBF_CHANNEL              =  "-PhD CBF Channel"; //This is somewhat similar to Donchian Channel
static string VOLATILITY_BANDS         =  "-PhD Volatility Bands 1.01";   
static string POLYFIT_BANDS            =  "-PhD PolyfitBands";
static string NON_LAG_ENVELOPES        =  "-PhD NonLag Envelopes";
static string DONCHIAN_CHANNEL         =  "-PhD Donchian Channel 2.0";
static string T3_BANDS                 =  "-PhD T3 Bands"; 
static string T3_BANDS_SQUARED         =  "-PhD T3 Bands Squared";// Smoothed version of T3_BANDS. The seem to give strong signal when they cross each other
static string BOLLINGER_BANDS          =  "-PhD Bollinger Bands";
static string FIBO_BANDS               =  "-PhD Fibo Bands";
static string QUANTILE_BANDS           =  "-PhD Quantile Bands";
static string JMA_BANDS                =  "-PhD JMA Bands";
static string SR_BANDS                 =  "-PhD SR Bands";
static string SE_BANDS                 =  "-PhD SE Bands";
static string MLS_BANDS                =  "-PhD MLS";
static string NON_LINEAR_KALMAN_BANDS  =  "-PhD NonLinearKalmanBands";
//END BANDS

//START TRIGGERS
static string NON_LINEAR_KALMAN        =  "-PhD NonLinearKalman";
static string LINEAR_MA                =  "-PhD Linear";
static string HULL_MA                  =  "-PhD HMA";
static string JURIK_FILTER             =  "-PhD Jurik filter";
static string NOLAG_MA                 =  "-PhD NonLagMA"; 
static string SUPERTREND               =  "-PhD SuperTrend";
static string SMOOTHED_DIGITAL_FILTER  =  "-PhD Smoothed Digital Filters";
static string BUZZER                   =  "-PhD Buzzer";
//ENDS TRIGGERS

//--------MISCELLANEOUS---------- 
extern bool debug = false;
datetime tradeExecutionTime = 0;
int signalTracker = -1;

double lastTradeExitAt = 0;

//-----EXITS---------------
static int OP_EXIT_BUY = -2;
static int OP_EXIT_SELL= -3;

//-----REVERSALS-----------
static int OP_BEARISH_REVERSAL   = 6;
static int OP_BULLISH_REVERSAL   = 7;
//--------MISCELLANEOUS---------- 

/* START local enums */
enum StochasticsValues {
   SIGNAL_VALUE,
   STOCHASTIC_VALUE
};

enum Zones {
   OVERBOUGHT,
   OVERSOLD,
   NORMAL
};

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
   UNKNOWN_SLOPE //This should not happen
};

enum Signal {
   BUY_SIGNAL,
   SELL_SIGNAL,
   NO_SIGNAL
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




/*TEMP */
datetime checkedBar = 0;
/* TEMP */


/* BUFFERS */
//START DYNAMIC_JURIK
static int DYNAMIC_JURIK_MAIN_VALUE          =  0; //Signal Line
static int DYNAMIC_JURIK_SLOPE_VALUE         =  1; //Use to gauge the slope. EMPTY_VALUE = BULLISH, !EMPTY_VALUE = BULLISH
static int DYNAMIC_JURIK_FIRST_UPPER_VALUE   =  5;
static int DYNAMIC_JURIK_SECOND_UPPER_VALUE  =  6;
static int DYNAMIC_JURIK_FIRST_LOWER_VALUE   =  4;
static int DYNAMIC_JURIK_SECOND_LOWER_VALUE  =  3;
static int DYNAMIC_JURIK_MIDDLE_VALUE        =  7;
//END DYNAMIC_JURIK

//START MAIN_STOCH
static int MAIN_STOCH_MAIN_VALUE          =  0; //2nd Upper
static int MAIN_STOCH_SECOND_LOWER_VALUE  =  1; 
static int MAIN_STOCH_FIRST_UPPER_VALUE   =  2;
static int MAIN_STOCH_FIRST_LOWER_VALUE   =  3;
static int MAIN_STOCH_SIGNAL              =  4;
static int MAIN_STOCH_SLOPE_VALUE         =  5;//Use to gauge the slope. EMPTY_VALUE = BULLISH, !EMPTY_VALUE = BULLISH
static int MAIN_STOCH_SECOND_UPPER_VALUE  =  6;
//END MAIN_STOCH

//START DONCHIAN_CHANNEL
static int DONCHIAN_CHANNEL_MAIN         =  0;
static int DONCHIAN_CHANNEL_UPPER_LEVEL  =  0;
static int DONCHIAN_CHANNEL_LOWER_LEVEL  =  1;
static int DONCHIAN_CHANNEL_MIDDLE_LEVEL =  2;
static int DONCHIAN_CHANNEL_SLOPE_LEVEL  =  4;
//END DONCHIAN_CHANNEL

//START DYNAMIC_PRICE_ZONE
static int DYNAMIC_PRICE_ZONE_LOWER_LEVEL  =  0;
static int DYNAMIC_PRICE_ZONE_UPPER_LEVEL  =  1;
static int DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL =  2;
//END DYNAMIC_PRICE_ZONE

//START JURIK_FILTER
static int JURIK_FILTER_MAIN_VALUE     =  0;
static int JURIK_FILTER_BULLISH_VALUE  =  0;
static int JURIK_FILTER_BEARISH_VALUE  =  1;
static int JURIK_FILTER_SLOPE          =  5;
//END JURIK_FILTER

//START SOMAT3
static int SOMAT3_SLOPE          =  0;
static int SOMAT3_BULLISH_MAIN   =  1;
static int SOMAT3_BULLISH_VALUE  =  1;
static int SOMAT3_BEARISH_VALUE  =  2;
//END SOMAT3

//START HULL_MA
static int HULL_MA_BULLISH_MAIN   =  0;
static int HULL_MA_BULLISH_VALUE  =  1;
static int HULL_MA_BEARISH_VALUE  =  2; 
//END HULL_MA

//START LINEAR_MA
static int LINEAR_MA_BULLISH_MAIN   =  0;
static int LINEAR_MA_BULLISH_VALUE  =  1;
static int LINEAR_MA_BEARISH_VALUE  =  2; 
//END LINEAR_MA

//START DYNAMIC_MPA
static int DYNAMIC_MPA_MAIN   = 0; //UPPER
static int DYNAMIC_MPA_MIDDLE = 2;
static int DYNAMIC_MPA_LOWER  = 4;
static int DYNAMIC_MPA_SIGNAL = 5; 
//END DYNAMIC_MPA

//START DYNAMIC_OF_AVERAGES
static int DYNAMIC_OF_AVAERAGES_SIGNAL       = 0;
static int DYNAMIC_OF_AVAERAGES_SECOND_LOWER = 1;
static int DYNAMIC_OF_AVAERAGES_FIRST_LOWER  = 2;
static int DYNAMIC_OF_AVAERAGES_FIRST_UPPER  = 3;
static int DYNAMIC_OF_AVAERAGES_SECOND_UPPER = 4;
static int DYNAMIC_OF_AVAERAGES_MIDDLE       = 5;
//END DYNAMIC_OF_AVERAGES

// START VOLATILITY_BANDS
static int VOLATILITY_BAND_MAIN  = 0; //MIDDLE
static int VOLATILITY_BAND_UPPER = 3;
static int VOLATILITY_BAND_LOWER = 4; // Buffer 4
static int VOLATILITY_BAND_SLOPE = 5; 
// END VOLATILITY_BANDS

// START SR_BANDS
static int SR_BAND_MAIN       = 0; //UPPER BAND
static int SR_BAND_LOWER      = 1;
static int SR_BULLISH_SLOPE   = 2;
static int SR_BEARISH_SLOPE   = 3; 
// END SR_BANDS

// START MLS_BANDS
static int MLS_BAND_MAIN      = 0; //UPPER BAND
static int MLS_BAND_LOWER     = 1;
// END MLS_BANDS

//START NON_LINEAR_KALMAN
static int NON_LINEAR_KALMAN_MAIN   = 0; 
static int NON_LINEAR_KALMAN_SLOPE  = 1; //Use to gauge the slope. EMPTY_VALUE = BULLISH, !EMPTY_VALUE = BULLISH
//END NON_LINEAR_KALMAN

//START T3_BANDS
static int T3_BANDS_UPPER_LEVEL  =  0;
static int T3_BANDS_MIDDLE_LEVEL =  1;
static int T3_BANDS_LOWER_LEVEL  =  2;
//END T3_BANDS

//START NON_LINEAR_KALMAN_BANDS
static int NON_LINEAR_KALMAN_BANDS_UPPER  =  0;
static int NON_LINEAR_KALMAN_BANDS_MIDDLE =  1;
static int NON_LINEAR_KALMAN_BANDS_LOWER  =  2;
//END NON_LINEAR_KALMAN_BANDS
   
//START T3_BANDS_SQUARED
static int T3_BANDS_SQUARED_UPPER_LEVEL  =  0;
static int T3_BANDS_SQUARED_MIDDLE_LEVEL =  1;
static int T3_BANDS_SQUARED_LOWER_LEVEL  =  2;
//END T3_BANDS_SQUARED_SQUARED

//JMA_BANDS
static int JMA_BANDS_UPPER = 0;
static int JMA_BANDS_LOWER = 1;
//JMA_BANDS
/* BUFFERS */

/* START SESSIONS */
Slope latestHmaSlope    = UNKNOWN_SLOPE;
Slope latestJurikSlope  = UNKNOWN_SLOPE;
Slope latestNonLinearKalmanSlope = UNKNOWN_SLOPE;

//Signals
Signal latestSignal = NO_SIGNAL;
Signal latestSrBandsSignal = NO_SIGNAL;
Signal latestMlsBandsSignal = NO_SIGNAL;
Signal donchianChannelLatestSignal = NO_SIGNAL;
Signal latestDynamicOfAveragesCrossSignal = NO_SIGNAL; 

Transition latestTransition = NO_TRANSITION;

//Tracking - Allow only 1 signal per candle
datetime latestSignalTime                    = 0; 
datetime latestTransitionTime                = 0; 
datetime latestMlsBandsSignalTime            = 0; 
datetime latestSrBandsSignalTime             = 0;
datetime latestJmaBandsReversalTime          = 0; 
datetime latestDynamicMpaFlatterTime         = 0;
datetime latestT3OuterBandsReversalTime      = 0;
datetime latestMainStochReversalTime         = 0;
datetime latestDynamicMpaReversalTime        = 0;
datetime latestDynamicJurikReversalTime      = 0;
datetime latestDynamicOfAveragesCrossTime    = 0;
datetime latestT3MiddleBandsReversalTime     = 0;
datetime latestNonLinearKalmanSlopeTime      = 0;
datetime latestDynamicOfAveragesReversalTime = 0;
datetime latestDynamicOfAveragesFlatterTime  = 0;
datetime latestNonLinearKalmanBandsReversalTime          = 0;
datetime latestDynamicOfAveragesCrossSignalTime          = 0;
datetime latestDynamicOfAveragesShortTermTrendTime       = 0;
datetime latestDynamicPriceZonesandJmaBandsReversalTime  = 0;
datetime latestDynamicMpaAndNonLinearKalmanBandsCrossTime= 0;


//Reversal
Reversal latestJmaBandsReversal              = UNKNOWN;
Reversal latestMainStochReversal             = UNKNOWN;
Reversal latestDynamicMpaReversal            = UNKNOWN;
Reversal latestT3OuterBandsReversal          = UNKNOWN;
Reversal latestT3MiddleBandsReversal         = UNKNOWN;
Reversal latestDynamicOfAveragesReversal     = UNKNOWN;
Reversal latestNonLinearKalmanBandsReversal  = UNKNOWN;
Reversal latestDynamicPriceZonesandJmaBandsReversal = UNKNOWN;

Flatter latestDynamicMpaFlatter = NO_FLATTER;
Flatter latestDynamicOfAveragesFlatter = NO_FLATTER;

//Trends
Trend latestDynamicOfAveragesShortTermTrend  = NO_TREND;

//Crosses
Cross latestDynamicOfAveragesCross = UNKNOWN_CROSS;

Cross latestDynamicMpaAndNonLinearKalmanBandsCross = UNKNOWN_CROSS;

/* END SESSIONS */

int OnInit() {
    
    Print("Initializing MacPhD v2017.05.21.19");  
    
   if (getTradeSetup()  == OP_BUY)   {
      
      initialTrendSetUp  =  OP_BUY;  
   }
   else if(getTradeSetup()  == OP_SELL)  {
      
      initialTrendSetUp  =  OP_SELL;      
   }
   
   return 0;
}  

int start() {
  openTrade();
  return 0;
}

void openTrade() {
   
   string methodName = "processTrade";
   
   //******************NEW*****************//
   /*
   if (getStepRsiTrigger()== OP_BUY) {
      Print("We buying " );
   }
   else if(getStepRsiTrigger() == OP_SELL) {
      Print("We SElling" );
   }
   */
   
   /*
   if (getOcnNmcAndMaTrigger()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getOcnNmcAndMaTrigger() == OP_SELL) {
      Print("We Selling" );
   }
   */
   
   /*if (getIRCTrippletsV2()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getIRCTrippletsV2() == OP_SELL) {
      Print("We Selling" );
   }
   */

   /*if (getIRCTripplets()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getIRCTripplets() == OP_SELL) {
      Print("We Selling" );
   }
   */
   /*
   if (getSOMAT3(55, 0.5, false)== OP_BUY) {
      Print("We Buying " );
   }
   else if(getSOMAT3(55, 0.5, false) == OP_SELL) {
      Print("We Selling" );
   }
   return; /*
   
   if (getMrTrigger()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getMrTrigger() == OP_SELL) {
      Print("We Selling" );
   }
   */
   
   /*
   if (getTrendScore()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getTrendScore() == OP_SELL) {
      Print("We Selling" );
   }
   */
   
   /*
   if (getVelocitySteps()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getVelocitySteps() == OP_SELL) {
      Print("We Selling" );
   }
   */
   /*if (getSaduki()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getSaduki() == OP_SELL) {
      Print("We Selling" );
   }*/

   /*if (getLevelStopTrend()== OP_BUY) {
      Print("We Buying " );
   }
   else if(getLevelStopTrend() == OP_SELL) {
      Print("We Selling" );
   }*/
   /*if (getPerfectTrend(0)== OP_BUY && getPerfectTrend(1)== OP_BUY) {
      Print("We Buying " );
   }
   else if(getPerfectTrend(0) == OP_SELL && getPerfectTrend(1)== OP_SELL) {
      Print("We Selling" );
   }*/
   
   /*
   if (getWcci(14, 18, false)== OP_BUY) {
      Print("We Buying " );
   }
   else if(getWcci(14, 18, false) == OP_SELL) {
      Print("We Selling" );
   }*/
   /*
   if (getQeVelocity(true)== OP_BUY) {
      Print("We Buying " );
   }
   else if(getQeVelocity(true) == OP_SELL) {
      Print("We Selling" );
   }*/
   /*
   if (getSomatricSystem(true)== OP_BUY) {
      Print("We Buying " );
   }
   else if(getSomatricSystem(true) == OP_SELL) {
      Print("We Selling" );
   }
   return;
*/
  /* if (getSomatricTwoMaCross(true) == OP_BUY) {
      Print("buy " );
   }
   else if(getSomatricTwoMaCross(true) == OP_SELL) {
      Print("Sell" );
   }   

   return;
   
  */ 
  /*
  if (getDySteppedStoch(true) == OP_BUY) {
      Print("buy " );
   }
   else if(getDySteppedStoch(true) == OP_SELL) {
      Print("Sell" );
   }   

   return;*/
   
   /*if (getDyNoLagMa(true) == OP_BUY) {
      Print("buy " );
   }
   else if(getDyNoLagMa(true) == OP_SELL) {
      Print("Sell" );
   }   
   return;   */
   
   /*
   if (getDyZOA(false) == OP_BUY) {
      Print("buy " );
   }
   else if(getDyZOA(false) == OP_SELL) {
      Print("Sell" );
   }   
   return;*/  

   
   /*if (getSOMALite(21, 1, 0.5, false)== OP_BUY) {
      Print("We Buying " );
   }
   else if(getSOMALite(21, 1, 0.5, false) == OP_SELL) {
      Print("We Selling" );
   }
   return;*/
   
   /*if (getSteppedMa(20, 4, 2, true)== OP_BUY) {
      Print("We Buying " );
   }
   else if( getSteppedMa(20, 4, 2, true) == OP_SELL) {
      Print("We Selling" );
   }
   return ; */
   /*
      if (getDiNoLagMa(false)== OP_BUY) {
         Print("We Buying " );
      }
      else if( getDiNoLagMa(false) == OP_SELL) {
         Print("We Selling" );
      }
      return ; */

   /*
   if (getDiMPA(false)== OP_BUY) {
      Print("We Buying " );
   }
   else if( getDiMPA(false) == OP_SELL) {
      Print("We Selling" );
   }
   return ;*/
   /*
   if (getDiEFT(false)== OP_BUY) {
      Print("We Buying " );
   }
   else if( getDiEFT(false) == OP_SELL) {
      Print("We Selling" );
   }
   return ;*/
   
   /*if (getDiWPRoffChart(false)== OP_BUY) {
      Print("We Buying " );
   }
   else if( getDiWPRoffChart(false) == OP_SELL) {
      Print("We Selling" );
   }
   return ;*/
   
   /*if (getRsiFilterTrend(false)== OP_BUY) {
      Print("We Buying " );
   }
   else if( getRsiFilterTrend(false) == OP_SELL) {
      Print("We Selling" );
   }
   return;*/
   /*if (getDiPriceZoneFlatDetector() == OP_BULLISH_REVERSAL) {
      //Print("Buy is emminent " );
   }
   else if( getDiPriceZoneFlatDetector() == OP_BEARISH_REVERSAL) {
      //Print("Sell is emminent" );
   }
   return;*/
   /*
   if (getDiEFTReversal()== OP_BUY) {
      Print("Bullish reversal!" );
   }
   else if( getDiEFTReversal() == OP_SELL) {
      Print("Bearish reversal!" );
   }
   return;   */
   
   //SL
   //getInitialStopLevel_v2(OP_BUY, 20);
   //getInitialStopLevel_v2(OP_SELL, 20));
   
   //getDyZOAStopLevel(OP_BUY, 10);
   //getDyZOAStopLevel(OP_SELL, 10);
   
   //return;
   
   /* TO COMPLETE ALL THE CONDITIONS
   //Trend Change Detection
   getSOMAT3DirectionChangeDetector();
   */
   //getTrendChangeByDiZOA();
   //getTrendChangeByDiMPA();
   //return;  
   
   //getNonLagMA(false); 
   //getStochasticSentiments(STOCHASTIC_VALUE, CURRENT_BAR);
   //getNoLagMaReversal();
   //getQuantileBandsReversal();
   //getEftSentiments();
   //getDonchianChannelOverlapTest();
   //getDynamicPriceZonesAndJurikFilterReversalTest();
   //getDynamicPriceZonesAndSomat3ReversalTest();
   //getDynamicPriceZonesAndLinearMaReversalTest();
   //getDynamicPriceZonesAndHullMaReversalTest();
   //getDimpaAndSomat3ReversalTest();
   //getDynamicMpaReversalTest();
   //getSrBandsSlopeTest();    
   //getDynamicPriceZonesAndVolitilityBandsReversalTest();
   //getJurikFilterSlopeTest();
   //getHullMaSlopeTest();
   //getDynamicPriceZonesAndSrBandsReversalTest();
   //getDynamicPriceZonesAndMlsBandsReversal();
   //getDynamicJuricSlopeTest();
   //getMainStochReversalTest();
   //getT3OuterBandsReversalTest();
   //getT3CrossSignalTest();
   //getNonLinearKalmanSlopeTest();
   //getDynamicPriceZonesAndMainStochTrendTest();   
   //getDynamicOfAveragesShortTermTrendTest();   
   //getDynamicMpaAndVolitilityBandsReversalTest();
   //getDynamicPriceZonesAndNonLinearKalmanBandsReversalTest();
   invalidateDynamicPriceZonesLinkedSignals(20);
   //getDynamicMpaAndNonLinearKalmanBandsCrossTest();
   getSomat3AndNonLinearKalmanCrossSlopeTest();
   //getNonLinearKalmanAndVolitilityBandsSlopeTest();
   //getSomat3AndVolitilityBandsSlopeTest();

   //getDynamicPriceZonesandJmaBandsReversalTest();
   //getJmaBandsLevelCrossReversalTest();  
   //getDynamicOfAveragesReversalTest();   
   return;
   
   //getAveragesBoundries(true);// Dynamic Zone
   //getTdiDirection(true);
   //******************NEW*****************//
   
   //******************OLD*****************//
   //getRsiDirection(21, true);
   //isPowerFuseBuy(0);
   //getPhDPrecision(1);
   /*if(isPhDSuperTrendV2Buy(1)) {
      
      Print("We buying " );
   }
   else if(isPhDSuperTrendV2Sell(1)) {
      Print("We Selling"  );
   }
   */

      
   int tradeSetup  =  getTradeSetup(); 
    
   if (OrdersTotal() > 0) {
   
      
      processTradeManagement(breakEvenTargetPoints, trailingStopPoints, targetPointsBeforeTrailingStop, CURRENT_BAR + 1 );

   } 
   else {
      if (reEnterOnNextSetup) {
         resetTradeSetupAttributes();
      }
   }
   
   int ticket = 0;

   if (isInLongPosition == false && (tradeSetup == OP_BUY)) { 

      if (rideTrend == false && initialTrendSetUp == OP_BUY) { 
         return;
      }      
      
      initialTrendSetUp =  OP_BUY;
      alreadyModified   =  false;
   
      if (OrdersTotal() > 0 && isInShortPosition == true) {
      
         if ( forceCloseOnOppositeSignal == true ) { 
            
            // Force close the SELL trade before the SL hits
            if (CloseOrder(retries)) {
               
               isInShortPosition = false; //reset only when we guaranteed that the OP_SELL order type has been closed
            }
            else {
            //Log any errors
            }
         
         }    
         else {

            //There's already a SELL trade, wait for its SL/TP to hit before opening BUY trade
            return;         

         }                 
      }
      else {
         //There were no open short position
         isInShortPosition = false; 
      }        
   
      /* At this point only place a trade if 2 conditions are met
       * 1. Current bar high must go up past the previous bar close(cross bar)
       * 2. Current bar close must be above the fast MA
       * 3. First bar after cross must close above open 
       * 4. Heiken Ashi Buy candles changed color in favor of buy          
       */
      comment           = buyComment;
      ticket = PlaceOrder(OP_BUY, comment, BUY_MAGIC_NUMBER, Green);

      // All conditions met, trend settings must change
      preConditionsMet = false; // Once used, reset until another setup

      //Error Tracking         
      if (ticket == -1) {
         int errorCode = GetLastError();
         Print("Error placing BUY order: " + ErrorDescription(errorCode));       
      }
      else {
         isInLongPosition  = true;      
      }         
   }
   else if (isInShortPosition == false && ( tradeSetup == OP_SELL) ) {  
      
      if (rideTrend == false && initialTrendSetUp == OP_SELL) { 
         return;
      }
      
      alreadyModified   =  false;
      initialTrendSetUp =  OP_SELL;
            

      if (OrdersTotal() > 0 && isInLongPosition == true) {  

         if ( forceCloseOnOppositeSignal == true ) { 
            
            // Force close the BUY trade before the SL hits
            if (CloseOrder(retries)) {
               isInLongPosition = false; //reset only when we guaranteed that the OP_BUY order type has been closed
            }
            else {
               // Log errors
            } 
        
         }    
         else {

            //There's already a BUY trade, wait for its SL/TP to hit before opening SELL trade
            return;

         }     
      }
      else {
         //There were no open short position
          isInLongPosition = false;
      }         
      
      /* At this point only place a trade if 2 conditions are met
       * 1. Current bar low must go down past the previous bar close(cross bar)
       * 2. Current bar close must be below the fast MA 
       * 3. First bar after cross must close below open          
       * 4. Heiken Ashi Buy candles changed color in favor of sell
       */
      comment           = sellComment;
      ticket = PlaceOrder(OP_SELL, comment, SELL_MAGIC_NUMBER, Red);
      
      // All conditions met, trend settings must change
      preConditionsMet = false; // Once use, reset until another setup

      //Error Tracking         
      if (ticket == -1) {
         int errorCode = GetLastError();
         Print("Error placing SELL order: " + ErrorDescription(errorCode));       
      }
      else {
         isInShortPosition = true;            
      }
      
   }     

   if (debug) {
      Print("preConditionsMet = " + (string) preConditionsMet);
      Print("isInShortPosition = " + (string) isInShortPosition);
      Print("isInLongPosition = " + (string) isInLongPosition);
      Print("alreadyModified  = " + (string) alreadyModified );
   }
}

// Check if ticket != -1, Call GetLastError() if it is to retrive error details
int PlaceOrder(int lOrderType, string orderComment, int lMagicNumber, color arrowColor) {

   string methodName = "PlaceOrder";
   
   double price            =  0.0;
   double initialStopLevel =  0.0;
   double takeProfitPrice  =  0.0;
   double slippagePrice       =  getSlipage(slippage);  
  
   RefreshRates(); // To make sure that we have the update data(price action details)
   if (lOrderType == OP_BUY) {
  
      price =  Ask; 
      
      initialStopLevel  =  getDiMPAstopLevel(OP_BUY, initialStopPoints);//getDyZOAStopLevel(OP_BUY, initialStopPoints);//getSomat3StopLevel(OP_BUY, initialStopPoints);
      takeProfitPrice   =  0; //getInitialTakeProfit(OP_BUY, initialTargetPoints); //D=200
      
      Print("Entering a Buy order. Ask: " + (string) price + ", SL: " + (string) initialStopLevel);

   }
   else if(lOrderType == OP_SELL) {
      
      price =  Bid; 
      
      initialStopLevel  =  getDiMPAstopLevel(OP_SELL, initialStopPoints);//getDyZOAStopLevel(OP_SELL, initialStopPoints);//getSomat3StopLevel(OP_SELL, initialStopPoints);
      takeProfitPrice   =  0; //getInitialTakeProfit(OP_SELL, initialTargetPoints);
      
      Print("Entering a Sell order. Bid: " + (string) price + ", SL: " + (string) initialStopLevel);         
      
   }
   
   return OrderSend(SYMBOL, lOrderType, lVolume, price, slippage, initialStopLevel, takeProfitPrice, orderComment, lMagicNumber, ORDER_EXPIRATION_TIME, arrowColor);
}

void processTradeManagement(int lBreakEvenPoints, int lTrailingStopPoints, int lTargetPointsBeforeTrailingStop, int pastCandleIndex) {

   if ( orderExists(SYMBOL) == false ) {
         
      // No open orders for this Symbol            
      if (reEnterOnNextSetup) { // If this is false - No follow up trades will be open on the same trend after both auto and manual TP/SL. 
                                // Setup attributes will only reset on the next setup.

         // If trades for this SYMBOL has been auto TPd, SLd. This SYMBOL won't be in OrdersTotal().
         // Therefore clearing attributes is required to make way for the next setup in the same trend. 
         resetTradeSetupAttributes();
      } 
      
      if (debug) {
         Print("Open orders: " + (string) OrdersTotal() + ". None for " + SYMBOL); 
         Print("Exit processTradeManagement."); 
      }
      
      //No open orders for this Symbol, thefore nothing to modify - return 
      return;
   }

   for (int count = 0; count < OrdersTotal(); count++) {
      
      if (OrderSelect(count, SELECT_BY_POS, MODE_TRADES)) {
      
         // Only open orders for current symbol
         if ( OrderCloseTime() == 0 && OrderSymbol() == SYMBOL) { 
         
            if (OrderType() == OP_BUY ) { 
            
               RefreshRates();
               
               if ( getTradeExit(OP_BUY) == OP_EXIT_BUY ) {

                  if (CloseOrder(retries)) {
                     isInLongPosition = false;
                  }
                  else {
                  //Log any errors
                  }                   
               }               
               return;
               
            } //end OP_BUY test
   
            else if( OrderType() == OP_SELL ) { 
            
               RefreshRates();
               
               if (  getTradeExit(OP_SELL) == OP_EXIT_SELL ) {
                  
                  Print("Closing....");
                  
                  if (CloseOrder(retries)) {
                     isInShortPosition = false;
                  }
                  else {
                  //Log any errors
                  }                  
               }                 
               return;
               
            } //end OP_SELL test
             
            // if this return has been matched, exit the iteration as there should only be 1 macth as per the design of this EA
            //return;
            
         } // end OrderCloseTime() && OrderSymbol() test

      
      } // end OrderSelect()
   
   } // end OrdersTotal()
}


int getTradeSetup() {
   
   int currentTrend = -1;
   
   if (false) {//{ (trendFilterEnabled) {
      
      if( getSOMAT3(period, sensitivityFactor, validatePreviousbar) == OP_BUY) {
         
         currentTrend = OP_BUY;
      }
      else if( getSOMAT3(period, sensitivityFactor, validatePreviousbar) == OP_SELL) {
         
         currentTrend = OP_SELL;
      }      
   }
   
   if (true) { //(autotradingEnabled) {
   
      if(false) {
         if ( tradeExecutionTime != Time[CURRENT_BAR] ) { // Dont buy multiple time on the same candle
   
            if ( (getDyZOA(true) == OP_BUY) ){//&& (getSomatricSystem(true) == OP_BUY) && (getSaduki() == OP_BUY)  ) { //(getPerfectTrend(0) == OP_BUY && getPerfectTrend(1) == OP_BUY) && 
                  
                  tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle
                  signalTracker = OP_BUY;
                  return OP_BUY;
            }
            else if ( (getDyZOA(true) == OP_SELL) ){ //&& (getSomatricSystem(true) == OP_SELL) && (getSaduki() == OP_SELL) ) { //(getPerfectTrend(0) == OP_SELL && getPerfectTrend(1) == OP_SELL) && 
            
                  tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle               
                  signalTracker = OP_SELL;
                  return OP_SELL;
            }            
   
         }    
      }
      if ( tradeExecutionTime != Time[CURRENT_BAR] ) { // Dont buy multiple time on the same candle

         /*if ( (getPerfectTrend(false) == OP_BUY) && (getSomatricSystem(true) == OP_BUY) && (getSaduki() == OP_BUY)  ) { //(getPerfectTrend(0) == OP_BUY && getPerfectTrend(1) == OP_BUY) && 
               
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle
               signalTracker = OP_BUY;
               return OP_BUY;
         }
         else if ( (getPerfectTrend(false) == OP_SELL) && (getSomatricSystem(true) == OP_SELL) && (getSaduki() == OP_SELL) ) { //(getPerfectTrend(0) == OP_SELL && getPerfectTrend(1) == OP_SELL) && 
         
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle               
               signalTracker = OP_SELL;
               return OP_SELL;
         }  */
         
         
         /*if ( (getDiWPRoffChart(false) == OP_BUY) ) { 
               
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle
               signalTracker = OP_BUY;
               return OP_BUY;
         }
         else if ( (getDiWPRoffChart(false) == OP_SELL)) {
         
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle               
               signalTracker = OP_SELL;
               return OP_SELL;
         } */   
         
         /*if ( (getDiMPA(true) == OP_BUY) ) { 
               
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle
               signalTracker = OP_BUY;
               return OP_BUY;
         }
         else if ( (getDiMPA(true) == OP_SELL)) {
         
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle               
               signalTracker = OP_SELL;
               return OP_SELL;
         }*/

         if ( (getDiEFT(false) == OP_BUY) && (getRsiFilterTrend(false) == OP_BUY) ) { //(getDiEFTReversal(false) == OP_BUY) && (getDiEFT(false) == OP_BUY) && (getRsiFilterTrend(false) == OP_BUY) 
               
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle
               signalTracker = OP_BUY;
               return OP_BUY;
         }
         else if ((getDiEFT(false) == OP_SELL)&& (getRsiFilterTrend(false) == OP_SELL) ) { //(getDiEFTReversal(false) == OP_SELL) && (getDiEFT(false) == OP_SELL) && (getRsiFilterTrend(false) == OP_SELL)
         
               tradeExecutionTime = Time[CURRENT_BAR]; //Track order time to avoid ordwering multiple times on same candle               
               signalTracker = OP_SELL;
               return OP_SELL;
         }

         

      }
      
   }   
      
   return -1;
}

int getTradeExit(int lOrderType) { //TODO: FIX

   if( tradeExecutionTime == Time[CURRENT_BAR]) {
      
      //Ignore if same candle we opened on
      return -1;
   }
   
   if (lOrderType == OP_BUY) { 
   
      double upperCurrent  =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR), Digits);
      double upperPrev     =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR + 1), Digits);
      if ( (upperCurrent == upperPrev) ) { 
      
         return OP_EXIT_BUY; 
      }       
      
   }
   else if(lOrderType == OP_SELL) {

      double lowerCurrent  =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR), Digits);
      double lowerPrev     =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR + 1), Digits);
      
      double signalPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 5, CURRENT_BAR), Digits); 
      double middlePrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 2, CURRENT_BAR), Digits); 
     
      if( (signalPrev > middlePrev) ) { 
         
         return OP_EXIT_SELL;
      }
      
   }

   return -1;
}



/*Start: DYNAMIC_MPA Setup */ 
int getDiMPA(bool _validatePreviousbar) {

   double upperCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR), Digits);
   double lowerCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR), Digits);
   double midLaneCurrent =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 2, CURRENT_BAR), Digits);
   
   double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 5, CURRENT_BAR), Digits);
   
   //We need the value to identify the slope
   double signalPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 5, CURRENT_BAR + 1), Digits); 

   if( _validatePreviousbar == false) {      


      if( (signalCurrent > signalPrev) && (signalCurrent > midLaneCurrent)) { 
      
         return OP_BUY; 
      } 
      else if( (signalCurrent < signalPrev) && (signalCurrent < midLaneCurrent) ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      
      double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR + 1), Digits);
      double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR + 1), Digits);
      double midLanePrev =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 2, CURRENT_BAR + 1), Digits);            
      
      if( (signalCurrent > signalPrev) && ( (signalCurrent > midLaneCurrent) && (signalPrev > midLanePrev)) ) { 
      
         return OP_BUY; 
      } 
      else if( (signalCurrent < signalPrev) && ( (signalCurrent < midLaneCurrent) && (signalPrev < midLanePrev) )  ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*End: DYNAMIC_MPA Setup */

/*Start: DYNAMIC_WPR_ON_CHART Setup */ 
int getDiWPRonChart(bool _validatePreviousbar) {

   double lowerCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_ON_CHART, 1, 10, 1, 3, CURRENT_BAR), Digits);
   double upperCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_ON_CHART, 1, 10, 1, 6, CURRENT_BAR), Digits);
   double midLaneCurrent=  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_ON_CHART, 1, 10, 1, 7, CURRENT_BAR), Digits);
   
   if( _validatePreviousbar == false) {      

      double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_ON_CHART, 1, 10, 1, 0, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalMaPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_ON_CHART, 1, 10, 1, 0, CURRENT_BAR + 1), Digits);


      if( (signalMaCurrent > signalMaPrev) && (signalMaCurrent > midLaneCurrent)) { 
      
         return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && (signalMaCurrent < midLaneCurrent) ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
   }
   
   return -1;
}
/*End: DYNAMIC_WPR_ON_CHART Setup */

/*Start: getSomatricSystem Setup */ 
int getSomatricSystem(bool _validatePreviousbar) {

   int setup = -1; 
   
   if ( _validatePreviousbar == false) {
   
      double lowerMaCurrentTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 0, CURRENT_BAR), Digits);
      double medianMaCurrentTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 0, CURRENT_BAR), Digits);
      double higherMaCurrentTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 1, 0, CURRENT_BAR), Digits);
      
      if( lowerMaCurrentTrend == 1 && medianMaCurrentTrend == 1 && higherMaCurrentTrend == 1) { 
      
         setup = OP_BUY;
      } 
      else if( lowerMaCurrentTrend == -1 && medianMaCurrentTrend == -1 && higherMaCurrentTrend == -1) { 
         
         setup = OP_SELL;
      }
      else {
         
         //If MA are not inline, not need to continue
         return -1;
      }
   

      double lowerMaCurrentValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR), Digits);
      double medianMaCurrentValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 1, CURRENT_BAR), Digits);
      double higherMaCurrentValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 1, 1, CURRENT_BAR), Digits);

      if( setup == OP_BUY && (lowerMaCurrentValue>  medianMaCurrentValue) && (medianMaCurrentValue > higherMaCurrentValue) ) {      
         
         return OP_BUY; 
      } 
      else if( setup == OP_SELL && (higherMaCurrentValue >  medianMaCurrentValue) && (medianMaCurrentValue > lowerMaCurrentValue) ) { 
            
         return OP_SELL; 
      }
   }
   else { 
   
      double lowerMaCurrentTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 0, CURRENT_BAR), Digits);
      double medianMaCurrentTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 0, CURRENT_BAR), Digits);
      double higherMaCurrentTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 1, 0, CURRENT_BAR), Digits);
      
      if( lowerMaCurrentTrend == 1 && medianMaCurrentTrend == 1 && higherMaCurrentTrend == 1) { 
      
         setup = OP_BUY;
      } 
      else if( lowerMaCurrentTrend == -1 && medianMaCurrentTrend == -1 && higherMaCurrentTrend == -1) { 
         
         setup = OP_SELL;
      }
      else {
         
         //If MA are not inline, not need to continue
         return -1;
      }   
   
      double lowerMaPrevTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 0, CURRENT_BAR + 1), Digits);
      double medianMaPrevTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 0, CURRENT_BAR + 1), Digits);
      double higherMaPrevTrend = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 1, 0, CURRENT_BAR + 1), Digits);
      
      if( lowerMaPrevTrend == 1 && medianMaPrevTrend == 1 && higherMaPrevTrend == 1) { 
      
         setup = OP_BUY;
      } 
      else if( lowerMaPrevTrend == -1 && medianMaPrevTrend == -1 && higherMaPrevTrend == -1) { 
         
         setup = OP_SELL;
      }
      else {
         
         //If MA are not inline, not need to continue
         return -1;
      }

      
      // Check previous and current candle
      double lowerMaCurrentValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR), Digits);
      double medianMaCurrentValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 1, CURRENT_BAR), Digits);
      double higherMaCurrentValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 1, 1, CURRENT_BAR), Digits);
      
      double lowerMaPrevValue  = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR + 1), Digits);
      double medianMaPrevValue = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 1, CURRENT_BAR + 1), Digits);
      double higherMaPrevValue= NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 1, 1, CURRENT_BAR + 1), Digits);
      
     //Only check current candle - Mostly for longer T3 filter periods, like 55
      if( setup == OP_BUY && ( (lowerMaCurrentValue >  medianMaCurrentValue) && (medianMaCurrentValue > higherMaCurrentValue) ) && 
            ((lowerMaPrevValue >  medianMaPrevValue) && (medianMaPrevValue > higherMaPrevValue)) ) {
         
         return OP_BUY; 
      } 
      else if( setup == OP_SELL && ( (higherMaCurrentValue >  medianMaCurrentValue) && (medianMaCurrentValue > lowerMaCurrentValue) ) &&
            ( (higherMaPrevValue >  medianMaPrevValue) && (medianMaPrevValue > lowerMaPrevValue) ) ) {
                        
         return OP_SELL; 
      }        
   }
   
   return -1;
}
/*End: getSomatricSystem Setup */

/*Start: getSomatricTwoMaCross Setup */ 
int getSomatricTwoMaCross(bool _validatePreviousbar) {

   if ( _validatePreviousbar == false) {

      double fastMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR), Digits);
      double slowMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 1, CURRENT_BAR), Digits);


      if( fastMaCurrent >  slowMaCurrent ) {      
         
         return OP_BUY;
      } 
      else if( slowMaCurrent > fastMaCurrent ) { 
            
         return OP_SELL; 
      }
   }
   else { 
      
      // Check previous and current candle
      double fastMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR), Digits);
      double slowMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 1, CURRENT_BAR), Digits);
      
      double fastMaPrev  = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR + 1), Digits);
      double slowMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.6, 1, CURRENT_BAR + 1), Digits);
      
      if( ( fastMaCurrent >  slowMaCurrent ) && (fastMaPrev > slowMaPrev) ) {
         
         return OP_BUY;
      } 
      else if( ( slowMaCurrent > fastMaCurrent ) && (slowMaPrev > fastMaPrev) ) {
                        
         return OP_SELL;
      }
        
   }

   return -1;
}
/*End: getSomatricTwoMaCross Setup */


/*Start: SOMAT3 Setup */ 
int getSOMAT3(int _period, double _sensitivityFactor, bool _validatePreviousbar) {

   if( _validatePreviousbar == false) {      

      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, _period, _sensitivityFactor, 0, CURRENT_BAR), Digits);
      
      //Only check current candle - Mostly for longer T3 filter periods, like 55
      if( trendCurrent == 1 ) { 
      
         return OP_BUY; 
      } 
      else if( trendCurrent == -1) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, _period, _sensitivityFactor, 0, CURRENT_BAR), Digits);      
      double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, _period, _sensitivityFactor, 0, CURRENT_BAR + 1), Digits);    
      
      if( (trendPrev == 1) && (trendCurrent == 1) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendPrev == -1) && (trendCurrent == -1)) { 
         
         return OP_SELL; 
      }   
   }
   
   return -1;
}
/*End: SOMAT3 Setup */

/*Start: SOMA_LITE Setup */ 
int getSOMALite(int _period, double _sensitivityFactor, int speed, bool _validatePreviousbar) {

   if( _validatePreviousbar == false) {      

      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMA_LITE, CURRENT_TIMEFRAME, _period, _sensitivityFactor, speed,  3, CURRENT_BAR), Digits);
      
      if( trendCurrent == EMPTY_VALUE ) { // Buffer 3 is empty when bullish trend
      
         return OP_BUY; 
      } 
      else if( trendCurrent != EMPTY_VALUE) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SOMA_LITE, CURRENT_TIMEFRAME, _period, _sensitivityFactor, speed,  3, CURRENT_BAR), Digits);
      double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SOMA_LITE, CURRENT_TIMEFRAME, _period, _sensitivityFactor, speed,  3, CURRENT_BAR + 1), Digits);
            
      if( (trendCurrent == EMPTY_VALUE) && (trendPrev == EMPTY_VALUE) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendCurrent != EMPTY_VALUE) && (trendPrev != EMPTY_VALUE)) { 
         
         return OP_SELL; 
      }   
   }
   
   return -1;
}
/*End: SOMA_LITE Setup */

/*Start: STEPPED_MA Setup */ 
int getSteppedMa(int _period, double _sensitivityFactor, int stepSize, bool _validatePreviousbar) {

   if( _validatePreviousbar == false) {      

      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), STEPPED_MA, _period, _sensitivityFactor, stepSize,  1, CURRENT_BAR), Digits);
      
      if( trendCurrent == EMPTY_VALUE ) { // Buffer 1 is empty when bullish trend
      
         return OP_BUY; 
      } 
      else if( trendCurrent != EMPTY_VALUE) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), STEPPED_MA, _period, _sensitivityFactor, stepSize,  1, CURRENT_BAR), Digits);
      double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), STEPPED_MA, _period, _sensitivityFactor, stepSize,  1, CURRENT_BAR + 1), Digits);
            
      if( (trendCurrent == EMPTY_VALUE) && (trendCurrent == trendPrev) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendCurrent != EMPTY_VALUE) && (trendPrev != EMPTY_VALUE)) { 
         
         return OP_SELL; 
      }   
   }
   
   return -1;
}
/*End: STEPPED_MA Setup */


/** START Perfect Trend Lines*/
int getPerfectTrend(bool _validatePreviousbar) {

   //Lines

   if( _validatePreviousbar == false) {

      double buffer0Current = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 0, CURRENT_BAR), Digits);
      double buffer1Current = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 1, CURRENT_BAR), Digits);
      
      /** Start Consolidation - Price between lines **/
      double buffer3Current = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 3, CURRENT_BAR), Digits);
      
      if (buffer3Current == EMPTY_VALUE && buffer1Current > buffer0Current) {
         
         //Bullish Consolidation;
         return -1;
      }
      
      else if (buffer3Current == EMPTY_VALUE && buffer0Current > buffer1Current) {
         
         //Bearish Consolidation;
         return -1;
      }   
     /** End Consolidation - Price between lines **/
   
      else if(buffer1Current > buffer0Current) {
   
         return OP_BUY;
      }
   
      else if(buffer0Current > buffer1Current) {
   
         return OP_SELL;
      }
   }
   else {
      double buffer0Current = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 0, CURRENT_BAR), Digits);
      double buffer1Current = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 1, CURRENT_BAR), Digits);
      
      double buffer0Prev = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 0, CURRENT_BAR + 1), Digits);
      double buffer1Prev = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 1, CURRENT_BAR + 1), Digits);


      /** Start Consolidation - Price between lines **/
      double buffer3Current = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 3, CURRENT_BAR), Digits);
      //double buffer3CurrentPrev = NormalizeDouble(iCustom(Symbol(), Period(), PERFECT_TREND, 3, CURRENT_BAR +1 ), Digits);
      
      if ( (buffer3Current == EMPTY_VALUE && buffer1Current > buffer0Current)) {
         
         //Bullish Consolidation;
         return -1;
      }
      
      else if ( (buffer3Current == EMPTY_VALUE && buffer0Current > buffer1Current) ) {
         
         //Bearish Consolidation;
         return -1;
      }   
     /** End Consolidation - Price between lines **/
   
      else if( (buffer1Current > buffer0Current) && (buffer1Prev > buffer0Prev)) {
   
         return OP_BUY;
      }
   
      else if( (buffer0Current > buffer1Current) && (buffer0Prev > buffer1Prev)) {
   
         return OP_SELL;
      }
   
   }
   
   
   return -1;
}
/** END Perfect Trend Lines*/

/*Start: QEPS Setup */ 
int getQeps(bool _validatePreviousbar) {

   if( _validatePreviousbar == false) {      

      double greenLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), QEPS, 3, CURRENT_BAR), Digits);
      double redLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), QEPS, 4, CURRENT_BAR), Digits);

      //Only check current candle - Mostly for longer T3 filter periods, like 55
      if( greenLineCurrent > redLineCurrent) { 
      
         return OP_BUY; 
      } 
      else if( redLineCurrent > greenLineCurrent ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double greenLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), QEPS, 3, CURRENT_BAR), Digits);
      double redLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), QEPS, 4, CURRENT_BAR), Digits);
      
      double greenLinePrev = NormalizeDouble(iCustom(Symbol(), Period(), QEPS, 3, CURRENT_BAR + 1), Digits);
      double redLinePrev = NormalizeDouble(iCustom(Symbol(), Period(), QEPS, 4, CURRENT_BAR + 1), Digits);
      
      if( (greenLineCurrent > redLineCurrent) && (greenLinePrev > redLinePrev)) { 
      
         return OP_BUY; 
      } 
      else if( (redLineCurrent > greenLineCurrent) && (redLinePrev > greenLinePrev) ) { 
         
         return OP_SELL; 
      }  
   }
   
   return -1;
}
/*End: QEPS Setup */

/*Start: QEVELO Setup */ 
int getQeVelocity(bool _validatePreviousbar) {

   if( _validatePreviousbar == false) {      

      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), QEVELO, 5, CURRENT_BAR), Digits);

      //Only check current candle - Mostly for longer T3 filter periods, like 55
      if( trendCurrent > 0) { 
      
         return OP_BUY; 
      } 
      else if( trendCurrent < 0 ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), QEVELO, 5, CURRENT_BAR), Digits);
      double trendPrevious = NormalizeDouble(iCustom(Symbol(), Period(), QEVELO, 5, CURRENT_BAR + 1), Digits);
      
      if( (trendCurrent > 0) && (trendPrevious > 0) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendCurrent < 0) && (trendPrevious < 0) ) { 
         
         return OP_SELL; 
      }  
   }
   
   return -1;
}
/*End: QEVELO Setup */

/*Start: DYNAMIC_STEEPPED_STOCH Setup */ 
int getDySteppedStoch(bool _validatePreviousbar) {

   double stochCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEEPPED_STOCH, CURRENT_TIMEFRAME, 3, CURRENT_BAR), Digits);
   double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEEPPED_STOCH, CURRENT_TIMEFRAME, 4, CURRENT_BAR), Digits);
   
   if( _validatePreviousbar == false) {      

      if( trendCurrent > stochCurrent) { 
      
         return OP_BUY; 
      } 
      else if( trendCurrent < stochCurrent ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double stochPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEEPPED_STOCH, CURRENT_TIMEFRAME, 3, CURRENT_BAR + 1), Digits);
      double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEEPPED_STOCH, CURRENT_TIMEFRAME, 4, CURRENT_BAR + 1), Digits);
      
      if( (trendCurrent > stochCurrent) && (trendPrev > stochPrev) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendCurrent < stochCurrent) && (trendPrev < stochPrev) ) { 
         
         return OP_SELL; 
      }  
   }
   
   return -1;
}
/*End: DYNAMIC_STEEPPED_STOCH Setup */

/*Start: DYNAMIC_OF_AVERAGES Setup */ 
int getDyZOA(bool _validatePreviousbar) {

   
   if( _validatePreviousbar == false) {      

      double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR + 1), Digits); 
      
      double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);


      if( (signalMaCurrent > signalMaPrev) && (signalMaCurrent > lowerMaCurrent)) { 
      
         return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && (signalMaCurrent < upperMaCurrent) ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle

      double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR + 1), Digits);
      
      
      double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);      
      
      double lowerMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR + 1), Digits);
      double upperMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR + 1), Digits); 
            
      if( (signalMaCurrent > signalMaPrev) && ( (signalMaCurrent > lowerMaCurrent) &&  (signalMaPrev > lowerMaPrev)) ) { 
         
            return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && ( (signalMaCurrent < upperMaCurrent) && (signalMaPrev < upperMaPrev) )  ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*End: DYNAMIC_OF_AVERAGES Setup */

/*Start: DYNAMIC_EFT Setup */ 
int getDiEFT(bool _validatePreviousbar) {
   
   double midLane1OneCurrent=  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 2, CURRENT_BAR), Digits);
   double midLane1TwoCurrent=  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 4, CURRENT_BAR), Digits);
   
   if( _validatePreviousbar == false) {      

      double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 3, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 3, CURRENT_BAR + 1), Digits); 

      if( (signalCurrent > signalPrev) && ( (signalCurrent > midLane1OneCurrent) && (signalCurrent > midLane1TwoCurrent)) ) { 
      
         return OP_BUY; 
      } 
      else if( (signalCurrent < signalPrev) && ( (signalCurrent < midLane1OneCurrent) && (signalCurrent < midLane1TwoCurrent)) ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle

     // double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 3, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
     // double signalMaPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 3, CURRENT_BAR + 1), Digits); 
      
      
      /*double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);      
      
      double lowerMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR + 1), Digits);
      double upperMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR + 1), Digits); 
            
      if( (signalMaCurrent > signalMaPrev) && ( (signalMaCurrent > lowerMaCurrent) &&  (signalMaPrev > lowerMaPrev)) ) { 
         
            return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && ( (signalMaCurrent < upperMaCurrent) && (signalMaPrev < upperMaPrev) )  ) { 
         
         return OP_SELL; 
      }*/
   }
   
   return -1;
}
/*End: DYNAMIC_EFT Setup */

/*Start: DYNAMIC_WPR_OFF_CHART Setup */ 
int getDiWPRoffChart(bool _validatePreviousbar) {

   double lowerCurrent =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_OFF_CHART, 10, 5, MODE_EMA, 1, CURRENT_BAR), Digits);
   double upperCurrent =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_OFF_CHART, 10, 5, MODE_EMA, 2, CURRENT_BAR), Digits);   
   
   if( _validatePreviousbar == false) {      

      double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_OFF_CHART, 10, 5, MODE_EMA, 4, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_OFF_CHART, 10, 5, MODE_EMA, 4, CURRENT_BAR + 1), Digits); 

      if( (signalCurrent > signalPrev) && ( (signalCurrent > upperCurrent) ) ) { 
      
         double lowerPrev =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_OFF_CHART, 10, 5, MODE_EMA, 1, CURRENT_BAR + 1), Digits);
      
         if( lowerCurrent == lowerPrev) {
         
            //We are making this compulsory
            return OP_BUY;
         }
      
         return -1;
      } 
      else if( (signalCurrent < signalPrev) && ( (signalCurrent < upperCurrent) ) ) { 
         
         double upperPrev =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_WPR_OFF_CHART, 10, 5, MODE_EMA, 2, CURRENT_BAR + 1), Digits);            
         
         //We are making this compulsory
         if( upperCurrent == upperPrev) {
            
            return OP_SELL; 
         }
         
         return -1;
         
      }        
   }
   else { 
      // Check previous and current candle
   }
   
   return -1;
}
/*End: DYNAMIC_WPR_OFF_CHART Setup */


/*Start: Trend change detection by DYNAMIC_EFT Setup */ 
int getTrendChangeByDiEFT() {

   double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 1, CURRENT_BAR), Digits);
   double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 1, CURRENT_BAR + 1), Digits); 
   
   double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 0, CURRENT_BAR), Digits);
   double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits);

   double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 3, CURRENT_BAR), Digits);
   
   //We need the value to identify the slope
   double signalPrev  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, 5, PRICE_CLOSE, 3, CURRENT_BAR + 1), Digits); 
   
   if( (lowerCurrent == lowerPrev) && (upperCurrent == upperPrev) ) {
      
         Print("No Trade.");
         return -1; //No Trade. Close any existing
   }
   else if( (signalCurrent > signalPrev) && (lowerCurrent == lowerPrev)) { 
   
      Print("Trending changing to up.");
      
      /*if( (signalCurrent > midLane1OneCurrent) || (signalCurrent > midLane1TwoCurrent)) {
         
         //Strong buy
      }*/
      
      return OP_BUY; 
   } 
   else if( (signalCurrent < signalPrev) && (upperCurrent == upperPrev) ) { 

      /*if( (signalCurrent < midLane1OneCurrent) || (signalCurrent < midLane1TwoCurrent)) {
         
         //Strong Sell
      }*/
      
      Print("Trending changing to down.");
      return OP_SELL; 
   } 
   
   return -1;
}
/*End: Trend change detection by DYNAMIC_EFT Setup */

/*Start: Trend change detection by DYNAMIC_MPA Setup */ 
int getTrendChangeByDiMPA() {

   double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 5, 0, CURRENT_BAR), Digits);
   
   //We need the value to identify the slope
   double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 5, 0, CURRENT_BAR + 1), Digits); 

   double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 4, 0, CURRENT_BAR), Digits);
   double upperMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 4, 0, CURRENT_BAR + 1), Digits); 
   
   double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 4, 4, CURRENT_BAR), Digits);
   double lowerMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 4, 4, CURRENT_BAR + 1), Digits);

   double midMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 4, 2, CURRENT_BAR), Digits);
   double midMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, 4, 2, CURRENT_BAR + 1), Digits);

   if( (lowerMaCurrent == lowerMaPrev) && (upperMaCurrent == upperMaPrev) ) {
      
         Print("No Trade.");
         return -1; //No Trade. Close any existing
   }
   else if( (signalMaCurrent > signalMaPrev) && (lowerMaCurrent == lowerMaPrev)) { 
   
      Print("Trending changing to up.");
      
      /*if(midMaCurrent == midMaPrev) {
         
         //Strong buy
      }*/
      
      return OP_BUY; 
   } 
   else if( (signalMaCurrent < signalMaPrev) && (upperMaCurrent == upperMaPrev) ) { 

      /*if(midMaCurrent == midMaPrev) {
         
         //Strong Sell
      }*/
      
      Print("Trending changing to down.");
      return OP_SELL; 
   } 
   
   return -1;
}
/*End: Trend change detection by DYNAMIC_MPA Setup */

/*Start: Trend change detection by DYNAMIC_OF_AVERAGES Setup */ 
int getTrendChangeByDiZOA() {

   double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR), Digits);
   
   //We need the value to identify the slope
   double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR + 1), Digits); 
   
   double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
   double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);
   
   double lowerMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR + 1), Digits);
   double upperMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR + 1), Digits); 

   if( validatePreviousbar == false) {      

      if( (lowerMaCurrent == lowerMaPrev) && (upperMaCurrent == upperMaPrev) ) {
         
            Print("No Trade.");
            return -1; //No Trade. Close any existing
      }
      else if( (signalMaCurrent > signalMaPrev) && (lowerMaCurrent == lowerMaPrev)) { 
      
         Print("Trending changing to up.");
         return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && (upperMaCurrent == upperMaPrev) ) { 
         
         Print("Trending changing to down.");
         return OP_SELL; 
      } 

   }
   
   return -1;
}
/*End: Trend change detection by DYNAMIC_OF_AVERAGES Setup */

/*Start: DYNAMIC_NOLAG_MA Setup */ 
int getDiNoLagMa(bool _validatePreviousbar) {
   
   double signalCurrent    =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_NOLAG_MA, 10, PRICE_CLOSE, true, 5, 0, CURRENT_BAR), Digits);
   double downTrendCurrent =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_NOLAG_MA, 10, PRICE_CLOSE, true, 5, 1, CURRENT_BAR), Digits); //For upTrend
   double upTrendCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_NOLAG_MA, 10, PRICE_CLOSE, true, 5, 4, CURRENT_BAR), Digits); //For downTrend
   double midLaneCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_NOLAG_MA, 10, PRICE_CLOSE, true, 5, 5, CURRENT_BAR), Digits); //For upTrend
   
   if( _validatePreviousbar == false) {      

      if( signalCurrent > midLaneCurrent) { 
      
         return OP_BUY; 
      } 
      else if( signalCurrent < midLaneCurrent ) { 
         
         return OP_SELL; 
      } 
   
   }
   /*else { 
      
      // Check previous and current candle
      double stochPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEEPPED_STOCH, CURRENT_TIMEFRAME, 3, CURRENT_BAR + 1), Digits);
      double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEEPPED_STOCH, CURRENT_TIMEFRAME, 4, CURRENT_BAR + 1), Digits);
      
      if( (trendCurrent > stochCurrent) && (trendPrev > stochPrev) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendCurrent < stochCurrent) && (trendPrev < stochPrev) ) { 
         
         return OP_SELL; 
      }  
   }
   */
   return -1;
}
/*End: DYNAMIC_NOLAG_MA Setup */
 
/*Start: wCCI Setup */ 
int getWcci(int turboCCi, int slowCci, bool _validatePreviousbar) {

   if( _validatePreviousbar == false) {      

      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), WCCI, CURRENT_TIMEFRAME, turboCCi, slowCci, 0, CURRENT_BAR), Digits);

      //Only check current candle - Mostly for longer T3 filter periods, like 55
      if( trendCurrent == 250 ) { 
      
         return OP_BUY; 
      } 
      else if( trendCurrent == -250) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), WCCI, CURRENT_TIMEFRAME, turboCCi, slowCci, 0, CURRENT_BAR), Digits);
      double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), WCCI, CURRENT_TIMEFRAME, turboCCi, slowCci, 0, CURRENT_BAR + 1), Digits);
      
      if( (trendPrev == 250) && (trendCurrent == 250) ) { 
      
         return OP_BUY; 
      } 
      else if( (trendPrev == -250) && (trendCurrent == -250)) { 
         
         return OP_SELL; 
      }   
   }
   
   return -1;
}
/*End: wCCI Setup */ 

/* Start: Trend direction using Saduki */
int getSaduki() {

   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);                                          

   bool isPreviousTriggered = false;
   
   double trendHigherValCurr = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 0, CURRENT_BAR), Digits);
   double trendLowerValCurr = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);
   double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 2, CURRENT_BAR), Digits);
       
   if( trendCurrent == 1 && trendHigherValCurr > trendLowerValCurr) {
   
      //Bullish setup
      isPreviousTriggered = true;
   } 
   else if( trendCurrent == -1 && trendLowerValCurr > trendHigherValCurr) { 
   
      //Bearish setup
      isPreviousTriggered = true;      
   }  
   
   if( isPreviousTriggered == false) {
      
      return -1;
   }   

   double trendHigherValPrev = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 0, CURRENT_BAR), Digits);
   double trendLowerValPrev = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);     
   double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 2, CURRENT_BAR + 1), Digits);
   
   if( trendPrev == 1 && trendHigherValPrev > trendLowerValPrev) {
   
      return OP_BUY; 
   } 
   else if( trendPrev == -1 && trendLowerValPrev > trendHigherValPrev) { 
   
      return OP_SELL;
   } 
   
   return -1;
}
/* End: Trend direction using Saduki */

/* Start: Trend Changing using Saduki - Uses current and previous trendHigherValCrr and trendLowerVal to test equality that suggests Trend changing*/
bool iaSadukiTrendChanging() {

   bool isTrendChaning = false;
   double trendHigherValCurr = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 0, CURRENT_BAR), Digits);
   double trendLowerValCurr = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);
       
   if( trendHigherValCurr == trendLowerValCurr) {
   
      isTrendChaning = true;
   } 
   else { 
   
      return false;
   }   

   double trendHigherValPrev = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 0, CURRENT_BAR), Digits);
   double trendLowerValPrev = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);     
   
   if( trendHigherValPrev == trendLowerValPrev) {
   
      return true;
   } 
   
   return false;
}
/* End: Trend Changing using Saduki */

/*Start: Entry listener using MR-Trigger */ 
int getMrTrigger() {

   bool isPreviousTriggered = false;
   
   double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), MR_TRIGGER, CURRENT_TIMEFRAME, 0, CURRENT_BAR), Digits); 
       
   if( trendCurrent == 1) {
   
      //Bullish setup
      isPreviousTriggered = true;
      //Print("Going up");
   } 
   else if( trendCurrent == -1 ) { 
   
      //Bearish setup
      isPreviousTriggered = true;      
      //Print("Going down");
      
   }  
   
   if( isPreviousTriggered == false) {
      
      return -1;
   }   
      
   double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), MR_TRIGGER, CURRENT_TIMEFRAME, 0, CURRENT_BAR + 1), Digits);          
   
   if( trendPrev == 1) {
   
      return OP_BUY; 
   } 
   else if( trendPrev == -1 ) { 
   
      return OP_SELL;
   }  
   
   return -1;
}
/* End: Entry listener using MR-Trigger */ 


/* Start: Entry listener using -PhD Velocity Steps */
int getVelocitySteps() {

   /* We can enter on 0 or (+/-)0.333 */

   bool isPreviousTriggered = false;
   
   double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), VELOCITY_STEPS, CURRENT_TIMEFRAME, 20, 0.5, 5, 0, CURRENT_BAR + 1), Digits);
       
   if( trendCurrent == 1) {
   
      //Bullish setup
      isPreviousTriggered = true;
      Print("Going up");
   } 
   else if( trendCurrent == -1 ) { 
   
      //Bearish setup
      isPreviousTriggered = true;      
      Print("Going down");
      
   }
   
   if( isPreviousTriggered == false) {
      
      return -1;
   }   
      
   double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), TREND_SCORE, CURRENT_TIMEFRAME, 6, 6, 0, CURRENT_BAR + 1), Digits);          
   
   if( trendPrev == 1) {
   
      return OP_BUY; 
   } 
   else if( trendPrev == -1 ) { 
   
      return OP_SELL;
   }  
   
   return -1;
}
/* End: Entry listener using -PhD Velocity Steps */


/*Start: Entry listener using -PhD TrendScore */ 
int getTrendScore() {

   /* We can enter on 0 or (+/-)0.333 */

   bool isPreviousTriggered = false;
   
   double trendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), TREND_SCORE, CURRENT_TIMEFRAME, 20, 20, 0, CURRENT_BAR + 1), Digits);
       
   if( trendCurrent == 1) {
   
      //Bullish setup
      isPreviousTriggered = true;
      Print("Going up");
   } 
   else if( trendCurrent == -1 ) { 
   
      //Bearish setup
      isPreviousTriggered = true;      
      Print("Going down");
      
   }  
   
   if( isPreviousTriggered == false) {
      
      return -1;
   }   
      
   double trendPrev = NormalizeDouble(iCustom(Symbol(), Period(), TREND_SCORE, CURRENT_TIMEFRAME, 6, 6, 0, CURRENT_BAR + 1), Digits);          
   
   if( trendPrev == 1) {
   
      return OP_BUY; 
   } 
   else if( trendPrev == -1 ) { 
   
      return OP_SELL;
   }  
   
   return -1;
}
/* End: Entry listener using -PhD TrendScore */


/* Trend change detector */ 
int getSOMAT3DirectionChangeDetector() {

   bool isPreviousTriggered = false;
   
   double lessSensivityFactor = 0.0;
   double highSensivityFactor = 0.5;
   double fast = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, lessSensivityFactor, 1, CURRENT_BAR), Digits); // Less Sensivity Factor
   double slow = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, highSensivityFactor, 1, CURRENT_BAR), Digits); // High Sensivity Factor

   //if( fast == slow) { 
   
      Print("Fast" + (string) fast);
      Print("Slow" + (string) slow);
   //} 
         
   //if( fast == slow) { 
   
      //Print("Trend Change Detected :)");
   //} 
   
   return -1;
}
/* Trend change detector */ 

int getOcnNmcAndMaTrigger() {

   bool isOcnNmcAndMaTrigger = false;
   
   //if NMC > NMF > MNA =  BULLISH
   double nmaPrev = NormalizeDouble(iCustom(Symbol(), Period(), OCN_NMC_AND_MA, 3, CURRENT_BAR + 1), Digits); //NMA
   double nmfPrev = NormalizeDouble(iCustom(Symbol(), Period(), OCN_NMC_AND_MA, 4, CURRENT_BAR + 1), Digits); //NMF
   double nmcPrev = NormalizeDouble(iCustom(Symbol(), Period(), OCN_NMC_AND_MA, 5, CURRENT_BAR + 1), Digits); //NMC
         
   if( nmcPrev > nmaPrev && nmcPrev > nmfPrev && nmfPrev > nmaPrev) { //NMC > NMF > MNA
   
      //Bullish setup
      isOcnNmcAndMaTrigger = true;
      //Print("Going up");
   } 
   else if( nmcPrev < nmaPrev && nmcPrev < nmfPrev && nmfPrev < nmaPrev ) { //NMC < NMF < MNA
   
      //Bearish setup
      isOcnNmcAndMaTrigger = true;      
      //Print("Going down");
      
   }  
   
   if( isOcnNmcAndMaTrigger == false) {
      
      //if the slow OcnNmcAndMa setup is not yet triggered, return immediately
      return -1;
   }   
      
   //if NMC > NMF > MNA =  BULLISH
   double nmaCurr = NormalizeDouble(iCustom(Symbol(), Period(), OCN_NMC_AND_MA, 3, CURRENT_BAR), Digits); //NMA
   double nmfCurr = NormalizeDouble(iCustom(Symbol(), Period(), OCN_NMC_AND_MA, 4, CURRENT_BAR), Digits); //NMF
   double nmcCurr = NormalizeDouble(iCustom(Symbol(), Period(), OCN_NMC_AND_MA, 5, CURRENT_BAR), Digits); //NMC
         
   if( nmcCurr > nmaCurr && nmcCurr > nmfCurr && nmfCurr > nmaCurr) { //NMC > NMF > MNA
   
      return OP_BUY; 
   } 
   else if( nmcCurr < nmaCurr && nmcCurr < nmfCurr && nmfCurr < nmaCurr ) { //NMC < NMF < MNA
   
      return OP_SELL;
   }  
   
   return -1;
}

int getIRCTripplets() {

   bool isPreviousTriggered = false;
   
   double signalPrev = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS, 0, CURRENT_BAR + 1), Digits); //Signal
   double resistencePrev = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS, 1, CURRENT_BAR + 1), Digits); //Resistence
   double supportPrev = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS, 2, CURRENT_BAR + 1), Digits); //Support
         
   if( signalPrev > 0) { 
   
      //Bullish setup
      isPreviousTriggered = true;
      Print("Going up");
   } 
   else if( signalPrev < 0 ) { 
   
      //Bearish setup
      isPreviousTriggered = true;      
      Print("Going down");
      
   }  
   
   if( isPreviousTriggered == false) {
      
      // Pre-condition failed
      return -1;
   }   
      
   /*
   double signalCurr = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS, 0, CURRENT_BAR + 1), Digits); //Signal
   double resistenceCurr = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS, 1, CURRENT_BAR + 1), Digits); //Resistence
   double supportCurr = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS, 2, CURRENT_BAR + 1), Digits); //Support
         
   if( bullishPrev > bearishPrev) { 
   
      //Bullish setup
      return OP_BUY; 
   } 
   else if( bullishPrev < bearishPrev  ) { 
   
      //Bearish setup
      return OP_SELL;
   }*/
   
   return -1;
}

int getIRCTrippletsV2() {

   bool isPreviousTriggered = false;
   
   double bullishPrev = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS_V2, 0, CURRENT_BAR + 1), Digits); //Bullish
   double bearishPrev = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS_V2, 1, CURRENT_BAR + 1), Digits); //Bearish

         
   if( bullishPrev > bearishPrev) { 
   
      //Bullish setup
      isPreviousTriggered = true;
      //Print("Going up");
   } 
   else if( bullishPrev < bearishPrev ) { 
   
      //Bearish setup
      isPreviousTriggered = true;      
      //Print("Going down");
      
   }  
   
   if( isPreviousTriggered == false) {
      
      // Pre-condition failed
      return -1;
   }   
      
   double bullishCurr = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS_V2, 0, CURRENT_BAR), Digits); //Bullish
   double bearishCurr = NormalizeDouble(iCustom(Symbol(), Period(), IRC_TRIPPLETS_V2, 1, CURRENT_BAR), Digits); //Bearish
         
   if( bullishPrev > bearishPrev) { 
   
      //Bullish setup
      return OP_BUY; 
   } 
   else if( bullishPrev < bearishPrev  ) { 
   
      //Bearish setup
      return OP_SELL;
   }
   
   return -1;
}

int getAveragesBoundries(bool usePreviousBar) {

   double triggerLineCurr = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 0, CURRENT_BAR), Digits); //DeepSkyBlue    
   double triggerLinePrev = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 0, CURRENT_BAR + 1), Digits); //DeepSkyBlue    
   double triggerLinePrev2 = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 0, CURRENT_BAR + 2), Digits); //DeepSkyBlue
   
   double greenLineCurr = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 2, CURRENT_BAR), Digits); // Green   
   double greenLinePrev = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 2, CURRENT_BAR + 1), Digits); // Green   
   double greenLinePrev2 = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 2, CURRENT_BAR + 2), Digits); // Green   
   
   double redLineCurr = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 4, CURRENT_BAR), Digits); //Red   
   double redLinePrev = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 4, CURRENT_BAR + 1), Digits); //Red   
   double redLinePrev2 = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 4, CURRENT_BAR + 2), Digits); //Red   

   double middleLinePrev = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Averages Boundries", 21, 6, 5, CURRENT_BAR + 1), Digits); //Peru 

   /*********FORMED TREND****************/
   if(triggerLinePrev > redLinePrev && triggerLinePrev > middleLinePrev) { //Long
      Print("--BULLISH--");
   }   
   else if(triggerLinePrev < greenLinePrev && triggerLinePrev < middleLinePrev) { //Short
      Print("--BEARISH--");
   }
   /*********FORMED TREND****************/
  
   /*********BULLISH SIGNALS****************/
   if(triggerLinePrev > greenLinePrev && triggerLinePrev2 < greenLinePrev2) { //Reversed
      Print("--BULISH REVERSAL--");
   }  
   else if(triggerLinePrev > redLinePrev && triggerLinePrev2 < redLinePrev2) { //Continuation
      Print("--BULISH CONTINUATION--");
   }   
   /*********BULLISH SIGNALS****************/
  
  
   /*********BEARISH SIGNALS****************/
   if(triggerLinePrev < redLinePrev && triggerLinePrev2 > redLinePrev2) { //Reversed
      Print("--BEARISH REVERSAL--");
   }
   
   if(triggerLinePrev < greenLinePrev && triggerLinePrev2 > greenLinePrev2) { //Continuation
      Print("--BEARISH CONTINUATION--");
   }   
   /*********BEARISH SIGNALS****************/
   
   
   
  // return -1;
   
   //if (rsiPriceLine > vbHigh) {
      
      /*if (usePreviousBar) {
         
         if (previous > RSI_MID_POINT_LEVEL) {

            Print("Bullish TDI");      
            return OP_BUY;       
         }
         else {
            return -1;
         }         
      }*/
      
   ///   Print("Bullish TDI");      
   //   return OP_BUY;   
  // }
   //else if (rsiPriceLine < vbLow) {
      
      /*if (usePreviousBar) {
         
         if (previous < RSI_MID_POINT_LEVEL) {
            
            Print("Bearish RSI");         
            return OP_SELL;      
         }
         else {
            return -1;
         }            
      }*/
      
      //Print("Bearish TDI");      
      //return OP_SELL;      
   //}   

   return -1;
}

int getTdiDirection(bool usePreviousBar) {

   double rsiPriceLine = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Turbo Diesel Injector", 0, CURRENT_BAR + 1), Digits);    //rsiPriceLine
   double MaBuf = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Turbo Diesel Injector", 4, CURRENT_BAR + 1), Digits);   //rsiPriceLine
   
   double vbHigh = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Turbo Diesel Injector", 1, CURRENT_BAR + 1), Digits); //Upper bands
   double vbLow = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Turbo Diesel Injector", 3, CURRENT_BAR + 1), Digits);  //Lower bands 
   
   double Mbl = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Turbo Diesel Injector", 2, CURRENT_BAR + 1), Digits);   //Market Base Line
   double MbBuf = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Turbo Diesel Injector", 5, CURRENT_BAR + 1), Digits);   //Trade Signal Line
   
   
   if(Mbl < vbHigh && Mbl > vbLow) {
      Print("Middle range 1");      
   }
   return -1;
   
   if (rsiPriceLine > vbHigh) {
      
      /*if (usePreviousBar) {
         
         if (previous > RSI_MID_POINT_LEVEL) {

            Print("Bullish TDI");      
            return OP_BUY;       
         }
         else {
            return -1;
         }         
      }*/
      
      Print("Bullish TDI");      
      return OP_BUY;   
   }
   else if (rsiPriceLine < vbLow) {
      
      /*if (usePreviousBar) {
         
         if (previous < RSI_MID_POINT_LEVEL) {
            
            Print("Bearish RSI");         
            return OP_SELL;      
         }
         else {
            return -1;
         }            
      }*/
      
      Print("Bearish TDI");      
      return OP_SELL;      
   }   

   return -1;
}



int getStepRsiTrigger() {

   bool isFastStepRsiTriggered = false;
   // Track slow StepRsi    
   double fastBufferCurr_slowStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 2, 0, CURRENT_BAR), Digits); //Green = Bullish
   double slowBufferCurr_slowStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 2, 1, CURRENT_BAR), Digits); //Red = Bearish
   double fastBufferPrev_slowStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 2, 0, CURRENT_BAR + 1), Digits); //Green = Bullish
   double slowBufferPrev_slowStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 2, 1, CURRENT_BAR + 1), Digits); //Red = Bearish
     
   if( (fastBufferPrev_slowStepRsi > slowBufferPrev_slowStepRsi && fastBufferCurr_slowStepRsi > slowBufferCurr_slowStepRsi) ) {
   
      //Bullish setup
      isFastStepRsiTriggered = true;
   } 
   else if( (slowBufferPrev_slowStepRsi > fastBufferPrev_slowStepRsi && slowBufferCurr_slowStepRsi > fastBufferCurr_slowStepRsi)) {
   
      //Bearish setup
      isFastStepRsiTriggered = true;      
   }   
   
   if( isFastStepRsiTriggered == false) {
      
      //if the slow StepRsi setup is not yet triggered, return immediately
      return -1;
   }   
   
   // Track fast StepRsi 
   double fastBufferPrev_fastStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 1, 0, CURRENT_BAR), Digits); //Green = Bullish
   double slowBufferPrev_fastStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 1, 1, CURRENT_BAR), Digits); //Red = Bearish
   double fastBufferCurr_fastStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 1, 0, CURRENT_BAR + 1), Digits); //Green = Bullish
   double slowBufferCurr_fastStepRsi = NormalizeDouble(iCustom(Symbol(), Period(), STEP_RSI, 21, 6, 1, 1, CURRENT_BAR + 1), Digits); //Red = Bearish
   if(fastBufferPrev_fastStepRsi > slowBufferPrev_fastStepRsi && fastBufferCurr_fastStepRsi > slowBufferCurr_fastStepRsi) {
      
      return OP_BUY;      
   }
   else if(slowBufferPrev_fastStepRsi > fastBufferPrev_fastStepRsi && slowBufferCurr_fastStepRsi > fastBufferCurr_fastStepRsi) {
      
      return OP_SELL;
   }      
   
   return -1;
}

/** START PhD Precision*/
int getPhDPrecision(int barIndex) {


   double turbo = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Precision", "55", "5", "5", 0, barIndex), Digits);
   double cci = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Precision", "55", "5", "5", 1, barIndex), Digits);
   double value3 = NormalizeDouble(iCustom(Symbol(), Period(), "-PhD Precision", "55", "5", "5", 2, barIndex), Digits);

  /* if(turbo > 200 ) {
      Print("Bullish");
      return -1;
   }
   
   else if(turbo < -200 ) {
      Print("Bearish");
      return -1;
   }   */

   if(cci > 200 ) {
      Print("Bullish");
      return -1;
   }
   
   else if(cci< -200 ) {
      Print("Bearish");
      return -1;
   }   

   
   return -1;
}
/** END PhD Precision*/


/** START Solar Winds*/
int getCciCloudDirection(int barIndex) {

   double value = NormalizeDouble(iCustom(Symbol(), Period(), "$_CC_Cloud_2", 13, 0, barIndex), Digits);
   
   if(value > 0) {

      return OP_BUY;
   }
   else if(value < 0) {

      return OP_SELL;
   }
   
   return -1;//(upValue != EMPTY_VALUE) && (upValue > 0 && priceClose > upValue); 
}
/** END Solar Winds*/

/** START Renko Street Trend*/
int getRenkoStreetDirection(int barIndex) {

   double value = NormalizeDouble(iCustom(Symbol(), Period(), "-RenkoStreet_Trend", 13, 1, barIndex), Digits);
   
   if(value == 1) {
      Print("Going up");
      return OP_BUY;
   }
   else if(value == 0) {
      Print("Going down");
      return OP_SELL;
   }
   
   return -1;//(upValue != EMPTY_VALUE) && (upValue > 0 && priceClose > upValue); 
}
/** END Renko Street Trend*/


/** START Power Fuse */
bool isPowerFuseBuy(int barIndex) {

   int band_period = 20;
   int fast = 12;
   int slow = 26;
   
   int smooth = 5;
   int std_dev = 1.0;

   
   double upBBMacd = NormalizeDouble(iCustom(Symbol(), Period(), "PowerFuse", 
                                          band_period, fast, slow, smooth, std_dev, 1, barIndex), Digits);
                                          
   double upperBand = NormalizeDouble(iCustom(Symbol(), Period(), "PowerFuse", 
                                          band_period, fast, slow, smooth, std_dev, 5, barIndex), Digits);                                          
          
   
   double downBBMacd = NormalizeDouble(iCustom(Symbol(), Period(), "PowerFuse", 
                                          band_period, fast, slow, smooth, std_dev, 2, barIndex), Digits);  
   double lowerBand = NormalizeDouble(iCustom(Symbol(), Period(), "PowerFuse", 
                                          band_period, fast, slow, smooth, std_dev, 6, barIndex), Digits);                                                                                    
                                          
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
   if(upBBMacd != EMPTY_VALUE && upBBMacd > upperBand) {
      
      Print("Going up");
   }
   else if(downBBMacd != EMPTY_VALUE && downBBMacd < lowerBand) {
      
      Print("Going down");
   }
   
   return false; 
}
/** END Power Fuse */



/** START PhD Trends */
bool getPhdTrendDirection(string timeFrame, int barIndex) {

   int look_back_period = 10;

   double price_direction = NormalizeDouble(iCustom(Symbol(), Period(), "PhD Trends", timeFrame, look_back_period, 0, barIndex), Digits);
                                          
   double priceClose =  iClose(SYMBOL, Period(), barIndex);                                          
   
   if(priceClose > price_direction) {
      
      Print("Going up");
   }
   else if(priceClose < price_direction) {
      
      Print("Going down");
   }
   
   return false; 
}
/** END PhD Trends */


/** START SuperTrend1 Buy*/
bool isSuperTrend1Buy(int barIndex) {

   double upValue = NormalizeDouble(iCustom(Symbol(), Period(), "--SuperTrend1", 0, barIndex), Digits);
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex);                                          
   

   return (upValue != EMPTY_VALUE) && (upValue > 0 && priceClose > upValue); 
}
/** END SuperTrend1 Buy */

/** START SuperTrend1 sell*/
bool isSuperTrend1Sell(int barIndex) {

   double downValue = NormalizeDouble(iCustom(Symbol(), Period(), "--SuperTrend1", 1, barIndex), Digits);
                                          
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex);                                          
   
   return (downValue != EMPTY_VALUE) && (downValue > 0 && downValue > priceClose); 
}
/** END SuperTrend1 sell */

/** START PhD SuperTrend Buy*/
bool isPhDSuperTrendBuy(int barIndex) {

   int nbr_periods = 10;
   double multiplier = 2.0;
   double upValue  = NormalizeDouble(iCustom(Symbol(), Period(), "--PhD SuperTrend", nbr_periods, multiplier, 0, barIndex), Digits);
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex);    
   
   return (upValue != EMPTY_VALUE) && (upValue > 0 && priceClose > upValue); 
}
/** END PhD SuperTrend Buy */

/** START PhD SuperTrend v2.0 sell*/
bool isPhDSuperTrendV2Sell(int barIndex) {

   int nbr_periods = 10;
   double multiplier = 2.0;
   double downValue  = NormalizeDouble(iCustom(Symbol(), Period(), "--PhD SuperTrend v2.0", nbr_periods, multiplier, 1, barIndex), Digits);
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex);                                          
   
   return (downValue != EMPTY_VALUE) && (downValue > 0 && downValue > priceClose); 
}
/** END PhD SuperTrend v2.0 sell */


/** START FX STRATEGIST MA */
bool isForexStrategistMaBuy(int barIndex) {

   int ma1_period = 8;
   int ma1_method = 3;
   int ma1_price = 5;
   
   int ma2_period = 11;
   int ma2_method = 3;
   int ma2_price = 5;
   
   double upperFxStrategistMa = NormalizeDouble(iCustom(Symbol(), Period(), "Forex Strategist MA", 
                                          ma1_period, ma1_method, ma1_price, ma2_period, ma2_method, ma2_price,  
                                          0, barIndex), Digits);
                                          
   double lowerFxStrategistMa = NormalizeDouble(iCustom(Symbol(), Period(), "Forex Strategist MA", 
                                          ma1_period, ma1_method, ma1_price, ma2_period, ma2_method, ma2_price,  
                                          1, barIndex), Digits);
                                          
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
   return ( 
            (upperFxStrategistMa > lowerFxStrategistMa) 
            && (priceClose > upperFxStrategistMa) 
           ); 
}

bool isForexStrategistMaSell(int barIndex) {
  
   int ma1_period = 8;
   int ma1_method = 3;
   int ma1_price = 5;
   
   int ma2_period = 11;
   int ma2_method = 3;
   int ma2_price = 5;
   
   double upperFxStrategistMa = NormalizeDouble(iCustom(Symbol(), Period(), "Forex Strategist MA", 
                                          ma1_period, ma1_method, ma1_price, ma2_period, ma2_method, ma2_price,  
                                          0, barIndex), Digits);
                                          
   double lowerFxStrategistMa = NormalizeDouble(iCustom(Symbol(), Period(), "Forex Strategist MA", 
                                          ma1_period, ma1_method, ma1_price, ma2_period, ma2_method, ma2_price,  
                                          1, barIndex), Digits);
                                          
   double priceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);                                          
                            
                                         
   return ( 
            (lowerFxStrategistMa > upperFxStrategistMa) 
            && (priceClose < lowerFxStrategistMa) 
          ); 
}
/** END FX STRATEGIST MA */


/** START Gann Hi-lo Activator SSL */
bool isGannHiLoActivatorBuy(int _period, int barIndex) {

   int lb = 52;
   int lb2 = 13;   
   
   double gann5213 = NormalizeDouble(iCustom(Symbol(), Period(), "Gann Hi-lo Activator SSL", _period, 0, barIndex), Digits);
                                          
   double priceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
   return (priceClose > gann5213); 
}

bool isGannHiLoActivatorSell(int _period, int barIndex) {
  
   int lb = 52;
   int lb2 = 13;   
   
   double gann5213 = NormalizeDouble(iCustom(Symbol(), Period(), "Gann Hi-lo Activator SSL", _period, 0, barIndex), Digits);
                                          
   double priceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
   return (priceClose < gann5213); 
}
/** START Gann Hi-lo Activator SSL */

/** START STOP LOSS COMPUTATIONS*/

/** Start - PhD_Super_Trend Stop Loss */
double getInitialStopLevel(int lOrderType, int linitialStopPoints) {
   
   double initialStopLossLevel  = 0.0; 
  
   if (lOrderType == OP_BUY) {

      double superTrendLevel  =  NormalizeDouble(iCustom(Symbol(), Period(), "PhD_Super_Trend", 0, CURRENT_BAR), Digits);  //Green line
      initialStopLossLevel    =  NormalizeDouble( superTrendLevel - (linitialStopPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {

      double superTrendLevel  =  NormalizeDouble(iCustom(Symbol(), Period(), "PhD_Super_Trend", 1, CURRENT_BAR), Digits);  //Red line
      initialStopLossLevel    =  NormalizeDouble( superTrendLevel + (linitialStopPoints * getDecimalPip()), Digits );
         
   }
 
   return initialStopLossLevel;
}
/** End - PhD_Super_Trend Stop Loss */

/** Start - DYNAMIC_PRICE_ZONE Stop Loss */
double getDynamicPriceZonesStopLossLevel(int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level.
   double dynamicPriceZonesLevel = getDynamicPriceZonesLevel(band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( dynamicPriceZonesLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( dynamicPriceZonesLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - DYNAMIC_PRICE_ZONE Stop Loss */

/** Start - DYNAMIC_OF_AVERAGES Stop Loss */
double getDynamicOfAveragesLevelStopLossLevel(int length, int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level.
   double dynamicOfAveragesLevel = getDynamicOfAveragesLevel(length, band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( dynamicOfAveragesLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( dynamicOfAveragesLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - DYNAMIC_OF_AVERAGES Stop Loss */

/** Start - QUANTILE_BANDS Stop Loss */
double getQuantileBandsStopLossLevel(int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level.
   double quantileBandsLevel = getQuantileBandsLevel(band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( quantileBandsLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( quantileBandsLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - QUANTILE_BANDS Stop Loss */

/** Start - VOLATILITY_BANDS Stop Loss */
double getVolitilityBandsStopLossLevel(int length, int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level. Bands should have changed slope direction
   double volitilityBandsLevel = getVolitilityBandsLevel(length, band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( volitilityBandsLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( volitilityBandsLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** End - VOLATILITY_BANDS Stop Loss */

/** Start - T3_BANDS Stop Loss */
double getT3BandsStopLossLevel(int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level. Bands should have changed slope direction
   double t3BandsLevel = getT3BandsLevel(band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( t3BandsLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( t3BandsLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - T3_BANDS Stop Loss */

/** Start - T3_BANDS_SQUARED Stop Loss */
double getT3BandsQuaredStopLossLevel(int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level. Bands should have changed slope direction
   double t3BandsSquaredLevel = getT3BandsSquaredLevel(band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( t3BandsSquaredLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( t3BandsSquaredLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - T3_BANDS_SQUARED Stop Loss */

/** Start - SMOOTHED_DIGITAL_FILTER Stop Loss */
double getSmoothedDigitalFilterStopLossLevel(int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level
   double smoothedDigitalFilterLevel = getSmoothedDigitalFilterLevel(buffer, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( smoothedDigitalFilterLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( smoothedDigitalFilterLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - SMOOTHED_DIGITAL_FILTER Stop Loss */

/** Start - JURIK_FILTER Stop Loss */
double getJurikFilterLevelStopLossLevel(int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR; //Use current bar as the previous will definately be in the direction of the trade for this indicator. 
   double jurikFilterLevel = getJurikFilterLevel(buffer, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( jurikFilterLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( jurikFilterLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - JURIK_FILTER Stop Loss */

/** Start - LINEAR_MA Stop Loss */
double getLinearMaStopLossLevel(int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR;
   double linearMaLevelLevel = getLinearMaLevel(buffer, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( linearMaLevelLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( linearMaLevelLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - LINEAR_MA Stop Loss */

/** Start - HULL_MA Stop Loss */
double getHullMaStopLossLevel(int length, int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR;  
   double hullMaLevel = getHullMaLevel(length, buffer, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( hullMaLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( hullMaLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - HULL_MA Stop Loss */

/** Start - SUPERTREND Stop Loss */
double getSuperTrendStopLossLevel(int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR; //Use current bar as the previous will definately be in the direction of the trade for this indicator. 
   //It doesn't not turn immediately, it first spikes to the opposite direction of the trade. 
   double superTrendLevel = getSuperTrendLevel(buffer, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( superTrendLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( superTrendLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - SUPERTREND Stop Loss */

/** Start - NOLAG_MA Stop Loss */
double getNoLagMaStopLossLevel(int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use previous bar to get a stable level
   double noLagMaMainValue = getNoLagMaLevel(buffer, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( noLagMaMainValue - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( noLagMaMainValue + (linitialStopPoints * getDecimalPip()), Digits );      
   }
   
   return initialStopLossLevel;
}
/** Start - NOLAG_MA Stop Loss */

/** Start - DYNAMIC_MPA Stop Loss */
double getDiMPAstopLevel(int lOrderType, int linitialStopPoints) {
   
   double initialStopLossLevel  = 0.0; 
   
   if (lOrderType == OP_BUY) {
   
      double lowerCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( lowerCurrent - (linitialStopPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {

      double upperCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, 10, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( upperCurrent + (linitialStopPoints * getDecimalPip()), Digits );
         
   }
 
   return initialStopLossLevel;
}
/** End - DYNAMIC_MPA Stop Loss */

/** Start - SOMAT3 Stop Loss */
double getSomat3StopLevel(int lOrderType, int linitialStopPoints) {
   
   double initialStopLossLevel  = 0.0; 
   
   if (lOrderType == OP_BUY) {
   
      double somatCurrentVal = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( somatCurrentVal - (linitialStopPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {


      double somatCurrentVal = NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, CURRENT_TIMEFRAME, 20, 0.4, 1, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( somatCurrentVal + (linitialStopPoints * getDecimalPip()), Digits );
         
   }
 
   return initialStopLossLevel;
}
/** End - SOMAT3 Stop Loss */

/** Start - DYNAMIC_OF_AVERAGES Stop Loss */
double getDyZOAStopLevel(int lOrderType, int linitialStopPoints) {
   
   double initialStopLossLevel  = 0.0; 

   if (lOrderType == OP_BUY) {
   
      double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( lowerMaCurrent - (linitialStopPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {

      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, CURRENT_TIMEFRAME, 4, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( upperMaCurrent + (linitialStopPoints * getDecimalPip()), Digits );
   }
 
   return initialStopLossLevel;
}
/** End - DYNAMIC_OF_AVERAGES Stop Loss */

/** Start - SADUKI Stop Loss */
double getInitialStopLevel_v2(int lOrderType, int linitialStopPoints) {
   
   double initialStopLossLevel  = 0.0; 
  
   if (lOrderType == OP_BUY) {
   
      //SADUKI BUY Stop loss
      double trendLowerValCurr = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( trendLowerValCurr - (linitialStopPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {

      //SADUKI SELL Stop loss
      double trendHigherValCurr = NormalizeDouble(iCustom(Symbol(), Period(), SADUKI, CURRENT_TIMEFRAME, 0, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( trendHigherValCurr + (linitialStopPoints * getDecimalPip()), Digits );
         
   }
 
   return initialStopLossLevel;
}
/** End - SADUKI Stop Loss */

/** End - PhD_Super_Trend Stop Loss */
/** END STOP LOSS COMPUTATIONS */

/** START - TAKE PROFIT COMPUTATIONS */
double getInitialTakeProfit(int lOrderType, int linitialTakeProfitPoints) {
   
   double linitialTakeProfit  = 0.0; 
  
   if (lOrderType == OP_BUY) {

      linitialTakeProfit    =  NormalizeDouble( Ask + (linitialTakeProfitPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {

      linitialTakeProfit    =  NormalizeDouble( Bid - (linitialTakeProfitPoints * getDecimalPip()), Digits );
         
   }

    return linitialTakeProfit;
}
/** END -  TAKE PROFIT COMPUTATIONS */

/** START TRADE MANAGEMENT */
bool breakEven(int orderTicket, double openPrice, int lOrderType) {
   
   double minimumModifyStopLoss = NormalizeDouble( (getDecimalPip() * 5), Digits );

   if (lOrderType == OP_BUY) {
      
      double breakEvenStopLoss = NormalizeDouble( openPrice + minimumModifyStopLoss, Digits );
      RefreshRates();
      bool modify =  OrderModify(orderTicket, Ask, breakEvenStopLoss, OrderTakeProfit(), ORDER_EXPIRATION_TIME, Purple);
      if (modify == false) {
         if (debug) {
            Print("OP_BUY: Error moving break even SP level by " + (string) breakEvenStopLoss +" pips. Ticket: " + (string) orderTicket);
         }
      } 
      return modify;
   }
      
   else if(lOrderType == OP_SELL) {

      double breakEvenStopLoss = NormalizeDouble( openPrice - minimumModifyStopLoss, Digits );
     
      RefreshRates();
      bool modify =  OrderModify(orderTicket, Bid, breakEvenStopLoss, OrderTakeProfit(), ORDER_EXPIRATION_TIME, Purple);
      if (modify == false) {
         if (debug) {
            Print("OP_SELL: Error moving break even SP level by " + (string) breakEvenStopLoss +" pips. Ticket: " + (string) orderTicket);
         }
      } 
      return modify;
   } 
   
   return false; 
}

bool takeProfit(int lOrderType) {
   
   double closePrice = NormalizeDouble( iOpen(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1), Digits );
   double decimalTargetPointsTrailingStop = NormalizeDouble( (getDecimalPip() * targetPointsTrailingStop), Digits );   

   if (lOrderType == OP_BUY) {
      
      double takeProfitStop = NormalizeDouble( closePrice - decimalTargetPointsTrailingStop, Digits );
      RefreshRates();
      bool modify =  OrderModify(OrderTicket(), Ask, takeProfitStop, OrderTakeProfit(), ORDER_EXPIRATION_TIME, Purple);
      if (modify == false) {
         if (debug) {
            Print("OP_BUY: Error moving SL level by " + (string) takeProfitStop +" pips. Ticket: " + (string) OrderTicket());
         }
      } 
      return modify;
   }
      
   else if(lOrderType == OP_SELL) {

      double takeProfitStop = NormalizeDouble( closePrice + decimalTargetPointsTrailingStop, Digits );
     
      RefreshRates();
      bool modify =  OrderModify(OrderTicket(), Bid, takeProfitStop, OrderTakeProfit(), ORDER_EXPIRATION_TIME, Purple);
      if (modify == false) {
         if (debug) {
            Print("OP_SELL: Error moving SL level by " + (string) takeProfitStop +" pips. Ticket: " + (string) OrderTicket());
         }
      } 
      return modify;
   } 
   
   return false; 
}

bool CloseOrder(int lRetries) {
   
   string methodName = "CloseOrder";
   
   bool isOrderClosed = false;
   double bidOrAskValue = NULL;
   
   for (int count = 0; count < OrdersTotal(); count++) {
      
      // If this returns false, it means there was an error
      if (OrderSelect(count, SELECT_BY_POS, MODE_TRADES)) {
         
         // Only open orders and current symbol
         if( OrderCloseTime() == 0 && OrderSymbol() == SYMBOL) { 
           
           RefreshRates(); 
           
            // Close Buy
            if(OrderType() == OP_BUY) {

               bidOrAskValue = Bid;
            }
   
            // Close Sell
            else if(OrderType() == OP_SELL) {
               bidOrAskValue = Ask; 
            }
            
            if (bidOrAskValue != NULL) {
   
               // Close selected order
               int try = 0;
               do {
               
                  try++;
                  isOrderClosed = OrderClose(OrderTicket(), NormalizeDouble(OrderLots(), Digits), bidOrAskValue, getSlipage(slippage), Yellow);
                  if (!isOrderClosed) {
                     Print("Order Close failed, order number: ", OrderTicket(), " Error: " + (string) GetLastError(), ErrorDescription(GetLastError()) );
                  }
                  else {
                     Print("Order Closed. Order number: ", OrderTicket());
                  }
               }
               while(!isOrderClosed && try != lRetries);    
               
               if (!isOrderClosed) {
                  // Do some logging of the error message;
                  int errorCode = GetLastError();
                  Print("Error closing ticket with magic number: " + (string) OrderTicket() + ": " + (string) GetLastError() + " - " + ErrorDescription(GetLastError()) ); 
                  // If you can't close a position, there might be an error. Send an email. Dont open any new postions
               }
               
            }        
         }
         
      }        
   }
   return isOrderClosed;
}
/** END TRADE MANAGEMENT */

bool orderExists(string symbol) {
   
   for (int count = 0; count < OrdersTotal(); count++) {

      if (OrderSelect(count, SELECT_BY_POS, MODE_TRADES)) {

         // Amongst the open orders, 1 is for this Symbol. Search for it.
         // Search only open orders and this symbol
         if ( OrderCloseTime() == 0 && OrderSymbol() == symbol) { 
            
            if (OrderType() == OP_BUY) { // scan for buy orders
               return true;
            }
            else if (OrderType() == OP_SELL) { // scan for sell orders
               return true;
            }
            
         } // end OrderCloseTime && OrderSymbol
            
      } // end OrderSelect(
   }
   
   return false;
}


double normalizeDouble(double price) {
   return (NormalizeDouble(price, Digits));
}

int getSlipage(int lSlippagePoints) {
   return lSlippagePoints * 10;
}

double getDecimalPip() {

   switch(Digits) {
      case 3: return(0.01); //e.g. EURJPY pair
      case 4: return(0.001); //e.g. USDRZA pair
      case 5: return(0.0001); //e.g. EURUSD pair
      default: return(0.01); //e.g. SP_CrudeOil
   }
}

bool CloseEnough(double num1, double num2) {
   /*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */
   
   if (num1 == 0 && num2 == 0) return(true); //0==0
   if (MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);
   
   //Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)

// clear attributes from previous setup for the new one
void resetTradeSetupAttributes() {
   
      initialTrendSetUp    =  -1;
      breakEven            =  false;
      isInLongPosition     =  false; 
      preConditionsMet     =  false;
      isInShortPosition    =  false;   
      alreadyModified      =  false;
}

/** START getLongStopLevel */
double getLongStopLevel() {

   int currentBar = 0;
   double superTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "--SuperTrend1", 0, currentBar), Digits);
   double initialStopLossLevel    =  NormalizeDouble( superTrendLevel - (initialStopPoints * getDecimalPip()), Digits );    
   return initialStopLossLevel; 
}
/** END getLongStopLevel */

/** START SuperTrend1 Buy*/
double getShortStopLevel() {

   int currentBar = 0;
   double superTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "--SuperTrend1", 1, currentBar), Digits);
   double initialStopLossLevel    =  NormalizeDouble( superTrendLevel + (initialStopPoints * getDecimalPip()), Digits );    
   return initialStopLossLevel;  
}
/** END getShortStopLevel */

/*Start: DYNAMIC_EFT Setup. This is just to detect reversal, not action it taken*/ 
int getDiEFTReversal(bool _validatePreviousbar) {
   
   int _period = 10;
   if( _validatePreviousbar == false) {

      double midLane1TwoCurrent  =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 4, CURRENT_BAR), Digits);
      double lowerLineCurrent    =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 0, CURRENT_BAR), Digits);
      double upperLineCurrent    =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 1, CURRENT_BAR), Digits);
      double lowerLinePrev       =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits);
      double upperLinePrev       =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 1, CURRENT_BAR + 1), Digits);
      
      if( (lowerLineCurrent == midLane1TwoCurrent) && (lowerLineCurrent == lowerLinePrev) ) { 
      
         return OP_BUY; 
      } 
      else if( (upperLineCurrent == midLane1TwoCurrent) && (upperLineCurrent == upperLinePrev) ) { 
         
         return OP_SELL; 
      }  
   }
   else {

      double midLane1TwoCurrent  =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 4, CURRENT_BAR), Digits);
      double lowerLineCurrent    =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 0, CURRENT_BAR), Digits);
      double upperLineCurrent    =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 1, CURRENT_BAR), Digits);
      
      double midLane1TwoPrev     =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 4, CURRENT_BAR + 1), Digits);      
      double lowerLinePrev       =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits);
      double upperLinePrev       =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 1, CURRENT_BAR + 1), Digits);
      
      if( (midLane1TwoCurrent > lowerLineCurrent) && ( (midLane1TwoPrev == lowerLinePrev) && (lowerLineCurrent == lowerLinePrev) ) ) { 
      
         return OP_BUY; 
      } 
      else if( (midLane1TwoCurrent < upperLineCurrent) &&  ((midLane1TwoPrev == upperLinePrev) && (upperLineCurrent == upperLinePrev)) ) { 
         
         return OP_SELL; 
      }
   
   }

   return -1;
}
/*End: DYNAMIC_EFT Setup */

/*Start: Trend RSI_FILTER Setup */ 
int getRsiFilterTrend(bool _validatePreviousbar) {

   double upTrendCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), RSI_FILTER, 5, 0, CURRENT_BAR), Digits);
   double downTrendCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), RSI_FILTER, 5, 1, CURRENT_BAR), Digits);
   
   if( _validatePreviousbar == false) {      


      if( (upTrendCurrent == 1 ) && (downTrendCurrent == 0) ) { 
      
         return OP_BUY; 
      } 
      else if( (downTrendCurrent == -1 ) && (upTrendCurrent == 0)  ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle
      
      double _upTrendCurrent   =  NormalizeDouble(iCustom(Symbol(), Period(), RSI_FILTER, 5, 0, CURRENT_BAR), Digits);
      double _downTrendCurrent =  NormalizeDouble(iCustom(Symbol(), Period(), RSI_FILTER, 5, 1, CURRENT_BAR), Digits);
      double _upTrendPrev      =  NormalizeDouble(iCustom(Symbol(), Period(), RSI_FILTER, 5, 0, CURRENT_BAR + 1 ), Digits);
      double _downTrendPrev    =  NormalizeDouble(iCustom(Symbol(), Period(), RSI_FILTER, 5, 1, CURRENT_BAR + 1 ), Digits);
      
      if( ( (_upTrendCurrent == 1 ) && (_downTrendCurrent == 0) ) && ( (_upTrendPrev == 1 ) && (_downTrendPrev == 0) ) ) { 
      
         return OP_BUY; 
      } 
      else if( ( (_downTrendCurrent == -1 ) && (_upTrendCurrent == 0) ) &&  ( (_downTrendPrev == -1 ) && (_upTrendPrev == 0) ) ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*End: Trend RSI_FILTER Setup  */

/*Start: BUZZER cross Setup */ 
int getBuzzerCrossSetup(bool _validatePreviousbar) {

   int _period = 20;

   //Fast
   double bullCloseCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_CLOSE, 1, CURRENT_BAR), Digits);
   double bearCloseCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_CLOSE, 2, CURRENT_BAR), Digits);     
   
   //Slow
   double bullOpenCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_OPEN, 1, CURRENT_BAR), Digits);
   double bearOpenCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_OPEN, 2, CURRENT_BAR), Digits);
   
   if( _validatePreviousbar == false) {      
   
      //Only check the (bullCloseCurrent > bullOpenCurrent or bullCloseCurrent < bullOpenCurrent) 

      if( (getBuzzer(false, PRICE_CLOSE)== OP_BUY) && (getBuzzer(false, PRICE_OPEN)== OP_BUY) && (bullCloseCurrent > bullOpenCurrent) ) { 
      
         return OP_BUY; 
      } 
      else if( (getBuzzer(false, PRICE_CLOSE)== OP_SELL) && (getBuzzer(false, PRICE_OPEN)== OP_SELL) && (bearCloseCurrent < bearOpenCurrent) ) { 
         
         return OP_SELL; 
      }
   }
   else { 
      
      //Only check the (bullCloseCurrent > bullOpenCurrent or bullCloseCurrent < bullOpenCurrent)       
      
      // Check previous and current candle
      if( (getBuzzer(true, PRICE_CLOSE)== OP_BUY) && (getBuzzer(true, PRICE_OPEN)== OP_BUY) && (bullCloseCurrent > bullOpenCurrent) ) { 
      
         return OP_BUY; 
      } 
      else if( (getBuzzer(true, PRICE_CLOSE)== OP_SELL) && (getBuzzer(true, PRICE_OPEN)== OP_SELL) && (bearCloseCurrent < bearOpenCurrent) ) { 
         
         return OP_SELL; 
      }        
   }
   
   return -1;
}
/*End: BUZZER cross Setup  */

/*Start: BUZZER Setup */ 
int getBuzzer(bool _validatePreviousbar, ENUM_APPLIED_PRICE appliedPrice) {

   int _period = 20;

   if( _validatePreviousbar == false) {      

      double bullCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, appliedPrice, 1, CURRENT_BAR), Digits);
      double bearCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, appliedPrice, 2, CURRENT_BAR), Digits);
      
      if( (bullCurrent != EMPTY_VALUE) && (bearCurrent == EMPTY_VALUE) ) { 
      
         return OP_BUY; 
      } 
      else if( (bearCurrent != EMPTY_VALUE) && (bullCurrent == EMPTY_VALUE) ) { 
         
         return OP_SELL; 
      }
   }
   else { 
      
      // Check previous and current candle
      double bullCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, appliedPrice, 1, CURRENT_BAR), Digits);
      double bearCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, appliedPrice, 2, CURRENT_BAR), Digits);
      double bullPrev = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, appliedPrice, 1, CURRENT_BAR + 1), Digits);
      double bearPrev = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, appliedPrice, 2, CURRENT_BAR + 1), Digits);
            
      if( (bullCurrent != EMPTY_VALUE && bullPrev != EMPTY_VALUE) && (bearCurrent == EMPTY_VALUE && bearPrev == EMPTY_VALUE) ) { 
      
         return OP_BUY; 
      } 
      else if( (bearCurrent != EMPTY_VALUE && bearPrev != EMPTY_VALUE) && (bullCurrent == EMPTY_VALUE && bullPrev == EMPTY_VALUE) ) { 
         
         return OP_SELL; 
      }   
   }
   
   return -1;
}
/*End: BUZZER Setup  */

/*Start: DYNAMIC_MACD_RSI Setup */ 
int getDiMacdRsi(bool _validatePreviousbar) {

   int decimalPlaces = 2;
   int    MacdFastPeriod  =  14;
   int    MacdSlowPeriod  =  21;
   int    RsiPeriod       =  7;

   if( _validatePreviousbar == false) {      

      double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 0, CURRENT_BAR), decimalPlaces );
      double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 1, CURRENT_BAR), decimalPlaces );
      //double middleCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod,2, CURRENT_BAR), decimalPlaces );
      double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 3, CURRENT_BAR), decimalPlaces );
      
      if( (signalCurrent == upperCurrent)) {
      
         return OP_BUY; 
      } 
      else if( (signalCurrent == lowerCurrent) ) {
         
         return OP_SELL; 
      }
   }
   else { 
      
      // Check previous and current candle
      double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 0, CURRENT_BAR), decimalPlaces );      
      double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 1, CURRENT_BAR), decimalPlaces );
      double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 3, CURRENT_BAR), decimalPlaces );

      double signalPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 0, CURRENT_BAR), decimalPlaces );
      double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 1, CURRENT_BAR + 1), decimalPlaces );
      double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MACD_RSI, MacdFastPeriod, MacdSlowPeriod, RsiPeriod, 3, CURRENT_BAR + 1), decimalPlaces );
      
      if( (signalCurrent == upperCurrent) && (signalPrev == upperPrev)) { //&& (signalCurrent > middleCurrent) 
      
         return OP_BUY; 
      } 
      else if( (signalCurrent == lowerCurrent)  && (signalPrev < lowerPrev) ) { //&& (signalCurrent < middleCurrent)
         
         return OP_SELL; 
      }
      
   }
   
   return -1;
}
/*End: DYNAMIC_MACD_RSI Setup  */

/*Start: DYNAMIC_PRICE_ZONE*/ 

/*Start: DYNAMIC_PRICE_ZONE level.*/ 
double getDiPriceZoneLevel(int barIndex) {

   double currentLow    = iLow(Symbol(), Period(), barIndex);
   double currentHigh   = iHigh(Symbol(), Period(), barIndex);
   
   double previousClose = iClose(Symbol(), Period(), barIndex + 1);   
   double middleCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 2, barIndex), Digits);

   if( ( currentHigh > middleCurrent) && (previousClose > middleCurrent) ) {
      
      //When the zones are treding up, keep track of the upper level
      return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 1, barIndex), Digits);         
   } 
   else if( (middleCurrent > currentLow ) && (middleCurrent > previousClose) ) {
      
      //When the zones are treding down, keep track of the lower level
      return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, barIndex), Digits );
   }
  
   return -1;
}
/*End: DYNAMIC_PRICE_ZONE level */

/*Start: DYNAMIC_PRICE_ZONE Trend identifier*/ 
int getDiPriceZoneTrend(bool _validatePreviousbar) {

   double buyPrice   =  Ask;
   double sellPrice  =  Bid;
   double middleCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 2, CURRENT_BAR), Digits);

   if( _validatePreviousbar == false) {      

      if( (buyPrice > middleCurrent) ) {
      
         return OP_BUY; 
      } 
      else if( (sellPrice < middleCurrent) ) {
         
         return OP_SELL; 
      }
   }
   else { 

      double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
      double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 1, CURRENT_BAR), Digits);      
      
      // Check previous and current candle
      double priceClosePrev =  iClose(Symbol(), Period(), CURRENT_BAR + 1);          
      double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
      double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 1, CURRENT_BAR + 1), Digits);
      double middlePrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 2, CURRENT_BAR + 1), Digits);

      if( (buyPrice > middleCurrent) && (priceClosePrev > middlePrev)) { 
      
         return OP_BUY; 
      } 
      else if( (sellPrice < middleCurrent) && (priceClosePrev < middlePrev) ) {
         
         return OP_SELL; 
      }
      
   }
   
   return -1;
}
/*End: DYNAMIC_PRICE_ZONE Trend identifier */

/*End: DYNAMIC_PRICE_ZONE */

/* 
   Start: DYNAMIC_PRICE_ZONE FlatDetector
   The trend should have been in place for a while(hence the check for a previous candle in getDiPriceZoneTrend(true)) for it to be expected to reverse
*/
int getDiPriceZoneFlatDetector() {

   int lookBack = 2;
 
   if (getDiPriceZoneTrend(true) == OP_BUY) {
         
      //Scan for bearish reversal
      double upperCurrent  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 1, CURRENT_BAR), Digits);      
      double upperPrev     = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 1, CURRENT_BAR + 1), Digits);
               
      if( (upperCurrent == upperPrev) && (isPriceWithinRange(upperCurrent, lookBack, OP_BUY)) ) {
      //With the lookback of 2, only curr and prev bars will be tested. 
      //So passing either lowerCurrent or lowerPrev will yield the same results as upperCurrent==upperPrev, and we want to test if price touched the lower line atleast once within 2 bars timeframe
      
         return OP_BEARISH_REVERSAL; 
      }               
   }
   else if(getDiPriceZoneTrend(true) == OP_SELL) {
   
      //Scan for bullish reversal
      double lowerCurrent  = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
      double lowerPrev     = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );

      if( (lowerCurrent == lowerPrev) && (isPriceWithinRange(lowerCurrent, lookBack, OP_SELL)) ) { 
      //With the lookback of 2, only curr and prev bars will be tested. 
      //So passing either lowerCurrent or lowerPrev will yield the same results as lowerCurrent==lowerPrev, and we want to test if price touched the lower line atleast once within 2 bars timeframe
      
         return OP_BULLISH_REVERSAL; 
      }   
   }
   
   return -1;
}
/*End: DYNAMIC_PRICE_ZONE FlatDetector  */

/*Start: getFlatDetector Setup */ 
int getFlatDetector() {

   datetime currentTime =  iTime(Symbol(), Period(), 0);

   int _period = 20;
   int decimalPlaces = 2;
   
   /* BUFFER */
   //Fast
   double fastCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_CLOSE, 0, CURRENT_BAR), decimalPlaces);
   double fastPrevious = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_CLOSE, 0, CURRENT_BAR + 1), decimalPlaces);
   //Slow
   double slowCurrent = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_OPEN, 0, CURRENT_BAR), decimalPlaces);
   double slowPrevious = NormalizeDouble(iCustom(Symbol(), Period(), BUZZER, _period, PRICE_OPEN, 0, CURRENT_BAR + 1), decimalPlaces);
   /* BUFFER */

   /* DYNAMIC_EFT */    
   double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 1, CURRENT_BAR), Digits);
   double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 1, CURRENT_BAR + 1), Digits); 
   
   double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 0, CURRENT_BAR), Digits);
   double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_EFT, _period, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits);
   /* DYNAMIC_EFT */       

   /* DYNAMIC_MPA */    
   double diMpaUpperCurrent  =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, _period, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR), Digits);
   double diMpaUpperPrev     =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, _period, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 0, CURRENT_BAR + 1), Digits);

   double diMpaLowerCurrent  =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, _period, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR), Digits);
   double diMpaLowerPrev     =  NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, _period, PRICE_CLOSE, DYNAMIC_MPA_METHOD, 4, CURRENT_BAR + 1), Digits);
   /* DYNAMIC_MPA */    
       
   if( (fastCurrent == fastPrevious) && (slowCurrent == slowPrevious)) {

      if( (upperCurrent == upperPrev) && (diMpaUpperCurrent == diMpaUpperPrev) ) {
      
         Print("Upper Flat Detectedon " + (string) currentTime );
      }
      else if( (lowerCurrent == lowerPrev) && (diMpaLowerCurrent == diMpaLowerPrev)) {
      
         Print("Lower Flat Detectedon " + (string) currentTime );
      }

   }
          
   return -1;
}
/*End: getFlatDetector Setup  */


bool isPriceWithinRange(double price, int numberOfPreviousBars, int bias) {
   
   if (bias == OP_BUY) {

      for ( int i =0; i < numberOfPreviousBars; i++ ) {
         
         double high =  iHigh(Symbol(), Period(), i);
         
         if(high > price) {
            
            return true;
         }
      }
   
   }
   else if(bias == OP_SELL) {

      for ( int i =0; i < numberOfPreviousBars; i++ ) {
         
         double low =  iLow(Symbol(), Period(), i);
         
         if(low < price) {
            
            return true;
         }         
      }

   }   

   return false;
}

/*START: DYNAMIC_PRICE_ZONE AND NON_LAG_ENVELOPES  */
/*This is a system on its own. It uses DYNAMIC_PRICE_ZONE and NON_LAG_ENVELOPES and */ 
int getPriceZoneAndNonLagEnvelopes(bool _validatePreviousbar) {

   int _period = 7;
   double deviation = 0.1;
   
   int reversalDirection = 0;
   
   double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 0, CURRENT_BAR), Digits);
   double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR), Digits);      
   double priceZoneMiddleLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 2, CURRENT_BAR), Digits);
  
   if( (priceZoneMiddleLineCurrent > upperCurrent) && (priceZoneMiddleLineCurrent > lowerCurrent) ) {
      
      //Bearish. Look for Bullish reversal
      //Print("Bearish. Look for Bullish reversal");
      reversalDirection = 1;
   }
   else if( (priceZoneMiddleLineCurrent < upperCurrent) && (priceZoneMiddleLineCurrent < lowerCurrent) ) {
   
      //Bullish. Look for Bearish reversal
      //Print("Bullish. Look for Bearish reversal");
      reversalDirection = -1;
   }

   if(reversalDirection == 1) {
      
      //Bearish. Look for Bullish reversal
      //Print("Bearish. Look for Bullish reversal");  
      
      if( _validatePreviousbar == false) {      
   
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR + 1), Digits); 
           
         double priceZoneLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
         double priceZoneLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
         if( (NolagEnvLowerPrev < priceZoneLowerPrev) &&  (NolagEnvLowerCurr > NolagEnvLowerCurr)) {
         
         }
       
      }
      else { 
         
         // Check previous and current candle
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR + 1), Digits); 
         double NolagEnvLowerPrevPrev = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR + 2), Digits); 
           
         double priceZoneLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
         double priceZoneLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
         double priceZoneLowerPrevPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 2), Digits );         
         
         if( (NolagEnvLowerPrevPrev < priceZoneLowerPrevPrev) &&  ( (NolagEnvLowerPrevPrev > priceZoneLowerPrevPrev) && (NolagEnvLowerCurr > priceZoneLowerCurr)) ) {
         
         }                   
      }       
   }
   else if(reversalDirection == -1){
      
      //Bullish. Look for Bearish reversal
      //Print("Bullish. Look for Bearish reversal");
      if( _validatePreviousbar == false) {      
   
   
       
      }
      else { 
         
         // Check previous and current candle
         upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 0, CURRENT_BAR), Digits);
         lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR), Digits);
         double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 0, CURRENT_BAR + 1), Digits);
         double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), NON_LAG_ENVELOPES, _period, deviation, 1, CURRENT_BAR + 1), Digits);  
            
      }         
   }
   
   return -1;
}
/*End: DYNAMIC_PRICE_ZONE AND NON_LAG_ENVELOPES  */

/*START: DYNAMIC_PRICE_ZONE AND NON_LAG_ENVELOPES  */
/*This is a system on its own. It uses DYNAMIC_PRICE_ZONE and VOLATILITY_BANDS */ 
int getPriceZoneAndVolatilityBands(bool _validatePreviousbar) {

   int _period = 15;
   double deviation = 0.5;
   bool useClassicalDeviations = true;
   
   int reversalDirection = 0;
   
   double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR), Digits);
   double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE, deviation, useClassicalDeviations, 2, CURRENT_BAR), Digits);      
   double priceZoneMiddleLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 2, CURRENT_BAR), Digits);
  
   if( (priceZoneMiddleLineCurrent > upperCurrent) &&  (priceZoneMiddleLineCurrent > lowerCurrent)) {
      
      //Bearish. Look for Bullish reversal
      Print("Bearish. Look for Bullish reversal");
      reversalDirection = 1;
   }
   else if( (priceZoneMiddleLineCurrent < lowerCurrent) && (priceZoneMiddleLineCurrent < upperCurrent)) {
   
      //Bullish. Look for Bearish reversal
      Print("Bullish. Look for Bearish reversal");
      reversalDirection = -1;
   }

   return -1;
   
   if(reversalDirection == 1) {
      
      //Bearish. Look for Bullish reversal
      //Print("Bearish. Look for Bullish reversal");  
      
      if( _validatePreviousbar == false) {      
   
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR + 1), Digits); 
           
         double priceZoneLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
         double priceZoneLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
         if( (NolagEnvLowerPrev < priceZoneLowerPrev) &&  (NolagEnvLowerCurr > NolagEnvLowerCurr)) {
         
         }
       
      }
      else { 
         
         // Check previous and current candle
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR + 1), Digits);           
         double NolagEnvLowerPrevPrev = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR + 2), Digits);
           
         double priceZoneLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
         double priceZoneLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
         double priceZoneLowerPrevPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 2), Digits );         
         
         if( (NolagEnvLowerPrevPrev < priceZoneLowerPrevPrev) &&  ( (NolagEnvLowerPrevPrev > priceZoneLowerPrevPrev) && (NolagEnvLowerCurr > priceZoneLowerCurr)) ) {
         
         }                   
      }       
   }
   else if(reversalDirection == -1){
      
      //Bullish. Look for Bearish reversal
      //Print("Bullish. Look for Bearish reversal");
      if( _validatePreviousbar == false) {      
   
   
       
      }
      else { 
         
         // Check previous and current candle
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, _period, PRICE_CLOSE,deviation, useClassicalDeviations, 1, CURRENT_BAR + 1), Digits);
                   
      }         
   }
   
   return -1;
}
/*End: DYNAMIC_PRICE_ZONE AND VOLATILITY_BANDS  */

/*START: DYNAMIC_PRICE_ZONE AND CBF_CHANNEL  */
/*This is a system on its own. It uses DYNAMIC_PRICE_ZONE and CBF_CHANNEL */ 
int getPriceZoneAndCbfChannel(bool _validatePreviousbar) {

   int minimalDepth = 5;
   
   int reversalDirection = 0;
   
   double upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 0, CURRENT_BAR), Digits);
   double lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 4, CURRENT_BAR), Digits);      
   double priceZoneMiddleLineCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 2, CURRENT_BAR), Digits);
  
   if( (priceZoneMiddleLineCurrent > upperCurrent) &&  (priceZoneMiddleLineCurrent > lowerCurrent)) {
      
      //Bearish. Look for Bullish reversal
      Print("Bearish. Look for Bullish reversal");
      reversalDirection = 1;
   }
   else if( (priceZoneMiddleLineCurrent < lowerCurrent) && (priceZoneMiddleLineCurrent < upperCurrent)) {
   
      //Bullish. Look for Bearish reversal
      Print("Bullish. Look for Bearish reversal");
      reversalDirection = -1;
   }

   return -1;
   
   if(reversalDirection == 1) {
      
      //Bearish. Look for Bullish reversal
      //Print("Bearish. Look for Bullish reversal");  
      
      if( _validatePreviousbar == false) {      
   
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 0, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 4, CURRENT_BAR + 1), Digits); 
           
         double priceZoneLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
         double priceZoneLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
         if( (NolagEnvLowerPrev < priceZoneLowerPrev) &&  (NolagEnvLowerCurr > NolagEnvLowerCurr)) {
         
         }
       
      }
      else { 
         
         // Check previous and current candle
         double NolagEnvLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 1, CURRENT_BAR), Digits);
         double NolagEnvLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 1, CURRENT_BAR + 1), Digits); 
         double NolagEnvLowerPrevPrev = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 1, CURRENT_BAR + 2), Digits); 
           
         double priceZoneLowerCurr = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR), Digits );
         double priceZoneLowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 1), Digits );
         double priceZoneLowerPrevPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, 0, CURRENT_BAR + 2), Digits );         
         
         if( (NolagEnvLowerPrevPrev < priceZoneLowerPrevPrev) &&  ( (NolagEnvLowerPrevPrev > priceZoneLowerPrevPrev) && (NolagEnvLowerCurr > priceZoneLowerCurr)) ) {
         
         }                   
      }       
   }
   else if(reversalDirection == -1){
      
      //Bullish. Look for Bearish reversal
      //Print("Bullish. Look for Bearish reversal");
      if( _validatePreviousbar == false) {      
   
   
       
      }
      else { 
         
         // Check previous and current candle
         upperCurrent = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 0, CURRENT_BAR), Digits);
         lowerCurrent = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 1, CURRENT_BAR), Digits);
         double upperPrev = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 0, CURRENT_BAR + 1), Digits);
         double lowerPrev = NormalizeDouble(iCustom(Symbol(), Period(), CBF_CHANNEL, minimalDepth, 1, CURRENT_BAR + 1), Digits);  
                   
      }         
   }
   
   return -1;
}
/*End: DYNAMIC_PRICE_ZONE AND CBF_CHANNEL  */

/*Start: LINEAR_MA Setup */ 
int getLinearMaSetup(bool _validatePreviousbar) {

   int length        = 10;     
   int filterPeriod  = 0; 
   double filter     = 2;  
   double filterOn   = 1.0;     
   
   if( _validatePreviousbar == false) {      

      double upTrendCurrent = getLinearMaLevel(1, CURRENT_BAR);            
      double downTrendCurrent = getLinearMaLevel(2, CURRENT_BAR); 

      if( (upTrendCurrent != EMPTY_VALUE) && (downTrendCurrent == EMPTY_VALUE)) { 
      
         //Print("Buy");
         return OP_BUY; 
      } 
      else if( (downTrendCurrent != EMPTY_VALUE)) { 
         
         //Print("Sell");
         return OP_SELL; 
      }     
   }
   else { 
      
      // Check previous and current candle
      double upTrendCurrent = getLinearMaLevel(1, CURRENT_BAR); 
      double downTrendCurrent = getLinearMaLevel(2, CURRENT_BAR);
      
      double upTrendPrev = getLinearMaLevel(1, CURRENT_BAR + 1); 
      double downTrendPrev = getLinearMaLevel(2, CURRENT_BAR + 2);     
            
      if( (upTrendCurrent != EMPTY_VALUE && upTrendPrev != EMPTY_VALUE)  && (downTrendCurrent == EMPTY_VALUE && downTrendPrev == EMPTY_VALUE) ) { 
      
         return OP_BUY; 
      } 
      else if( (downTrendCurrent != EMPTY_VALUE)  && (upTrendPrev == EMPTY_VALUE) ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*END: LINEAR_MA Setup */ 

/*Start: NOLAG_MA Setup */ 
int getNonLagMaSetup(bool _validatePreviousbar) {

   int     length         = 10;  
   int     price          = PRICE_CLOSE; 
   double  aFactor       = 3;  
   int     sFactor       = 0;  
   double  gFactor       = 1;  
   double  pctFilter      = 1;  
   
   if( _validatePreviousbar == false) {      

      double upTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, price, aFactor, sFactor, gFactor, pctFilter, 1, CURRENT_BAR), Digits);
      double downTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, price, aFactor, sFactor, gFactor, pctFilter, 2, CURRENT_BAR), Digits);

      if( (upTrendCurrent != EMPTY_VALUE) && (downTrendCurrent == EMPTY_VALUE)) { 
      
         //Print("Buy");
         return OP_BUY; 
      } 
      else if( (downTrendCurrent != EMPTY_VALUE) && (upTrendCurrent == EMPTY_VALUE) ) { 
         
         //Print("Sell");
         return OP_SELL; 
      }     
   }
   else { 
      
      // Check previous and current candle
      double upTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, price, aFactor, sFactor, gFactor, pctFilter, 1, CURRENT_BAR), Digits);
      double downTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, price, aFactor, sFactor, gFactor, pctFilter, 2, CURRENT_BAR), Digits); 
      
      double upTrendPrev = NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, price, aFactor, sFactor, gFactor, pctFilter, 1, CURRENT_BAR + 1), Digits);
      double downTrendPrev = NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, price, aFactor, sFactor, gFactor, pctFilter, 2, CURRENT_BAR + 1), Digits);       
            
      if( (upTrendCurrent != EMPTY_VALUE && upTrendPrev != EMPTY_VALUE)  && (downTrendCurrent == EMPTY_VALUE && downTrendPrev == EMPTY_VALUE) ) { 
      
         return OP_BUY; 
      } 
      else if( (downTrendCurrent != EMPTY_VALUE && downTrendPrev != EMPTY_VALUE)  && (upTrendCurrent == EMPTY_VALUE && upTrendPrev == EMPTY_VALUE) ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*END: NOLAG_MA Setup */ 

/*Start: SUPERTREND Setup */ 
int getSuperTrendSetup(bool _validatePreviousbar) {

   ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;
   int     length        = 10;  
   double  mutliplier    = 3;  
   
   if( _validatePreviousbar == false) {      

      double upTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, timeFrame, length, mutliplier, 0, CURRENT_BAR), Digits);
      double downTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, timeFrame, length, mutliplier, 1, CURRENT_BAR), Digits);

      if( (upTrendCurrent != EMPTY_VALUE) && (downTrendCurrent == EMPTY_VALUE)) { 
      
         //Print("Buy");
         return OP_BUY; 
      } 
      else if( (downTrendCurrent != EMPTY_VALUE)) { 
         
         //Print("Sell");
         return OP_SELL; 
      }     
   }
   else { 
      
      // Check previous and current candle
      double upTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, timeFrame, length, mutliplier, 0, CURRENT_BAR), Digits);
      double downTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, timeFrame, length, mutliplier, 1, CURRENT_BAR), Digits);
      
      double upTrendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, timeFrame, length, mutliplier, 0, CURRENT_BAR + 1), Digits);
      double downTrendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, timeFrame, length, mutliplier, 1, CURRENT_BAR + 1), Digits);    
            
      if( (upTrendCurrent != EMPTY_VALUE && upTrendPrev != EMPTY_VALUE)  && (downTrendCurrent == EMPTY_VALUE && downTrendPrev == EMPTY_VALUE) ) { 
      
         return OP_BUY; 
      } 
      else if( (downTrendCurrent != EMPTY_VALUE && downTrendPrev != EMPTY_VALUE)  && (upTrendCurrent == EMPTY_VALUE && upTrendPrev == EMPTY_VALUE) ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*END: NOLAG_MA Setup */ 

/*Start: STOCHASTIC Setup */ 
int getStochasticSetup(bool _validatePreviousbar) {

   ENUM_TIMEFRAMES timeFrame  =  PERIOD_CURRENT;
   ENUM_MA_METHOD mAMethod    =  MODE_EMA;
   int            kPeriod     =  10,
                  dPeriod     =  3,
                  slowing     =  3;   
   
   if( _validatePreviousbar == false) {      

      double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 0, CURRENT_BAR), Digits); //Signal
      double stochCurrent = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 1, CURRENT_BAR), Digits); //Stoch 

      if( stochCurrent > signalCurrent ) { 
      
         //Print("Buy");
         return OP_BUY; 
      } 
      else if( signalCurrent > stochCurrent ) { 
         
         //Print("Sell");
         return OP_SELL; 
      }     
   }
   else { 
      
      // Check previous and current candle
      double signalCurrent = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 0, CURRENT_BAR), Digits); //Signal
      double stochCurrent = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 1, CURRENT_BAR), Digits); //Stoch 
      
      double signalPrev = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 0, CURRENT_BAR + 1), Digits); //Signal
      double stochPrev = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 1, CURRENT_BAR + 1), Digits); //Stoc  
            

      if( (stochCurrent > signalCurrent)  && (stochPrev > signalPrev) ) { 
      
         //Print("Buy");
         return OP_BUY; 
      } 
      else if( (signalCurrent > stochCurrent) && (signalPrev > stochPrev) ) { 
         
         //Print("Sell");
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*END: STOCHASTIC Setup */ 

/*Start: EFT Sentiments */ 
Zones getEftSentiments() {
                  
   double overBoughtLevel = 6.0;
   double overSoldLevel = -6.0;               
   double eftLevel = getEftLevel(0, 0);
   
   if (eftLevel > overBoughtLevel) {
      
      Print("OVERBOUGHT");
      return OVERBOUGHT;
   }
   else if(eftLevel < overSoldLevel) {
   
      Print("OVERSOLD");
      return OVERSOLD;
   }
   else {
   
      return NORMAL;
   }
}
/*END: EFT Sentiments */ 

/*Start: STOCHASTIC Sentiments */ 
Zones getStochasticSentiments(StochasticsValues targetValue, int barIndex) {

   ENUM_TIMEFRAMES timeFrame  =  PERIOD_CURRENT;
   ENUM_MA_METHOD mAMethod    =  MODE_EMA;
   int            kPeriod     =  10,
                  dPeriod     =  3,
                  slowing     =  3;   
                  
                  
   double value = 0;
   if (targetValue == SIGNAL_VALUE) {
      
      value = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 0, barIndex), Digits); //Signal
   }
   else if(targetValue == STOCHASTIC_VALUE) {
   
      value = NormalizeDouble(iCustom(Symbol(), Period(), STOCHASTIC, timeFrame, mAMethod, kPeriod, dPeriod, slowing, 1, barIndex), Digits); //Stoch 
   }
   
   if(value < 10) {
   
      return OVERSOLD;
   }
   else if(value > 90) {
      
      return OVERBOUGHT;
   }
   else {
   
      return NORMAL;
   }
}
/*END: STOCHASTIC Sentiments */ 

/** START INVALIDATE SIGNALS*/
//DYNAMIC_PRICE_ZONE Linked

void invalidateDynamicPriceZonesLinkedSignals(int length){

   //Need a way to invalidate when invalidate when bands fails to touch DYNAMIC_PRICE_ZONE middle line and quickly turn
   //The distance between the bands must be decreasing. In bullish, bands must be heading up and YNAMIC_PRICE_ZONE middle line heading down. 
   //In bearish, bands must be heading down and DYNAMIC_PRICE_ZONE middle line heading up
   invalidateNonLinearKalmanBandsReversal(15);
   
   //RELOOK
   /*if(latestDynamicOfAveragesReversal == UNKNOWN) {
   
      Print("UNKNOWN at " + getCurrentTime() );
   }
   
   if( (latestDynamicOfAveragesReversal == BEARISH_REVERSAL) && (getDynamicOfAveragesShortTermTrend(length) != BULLISH_SHORT_TERM_TREND) ) {
      
      int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
      int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);
      
      if(latestDynamicOfAveragesReversalBarShift > 2) {
         
         Print("BEARS DEVIATED at " + getCurrentTime() );
      }
   } 
   
   if( (latestDynamicOfAveragesReversal == BULLISH_REVERSAL) && (getDynamicOfAveragesShortTermTrend(length) != BULLISH_SHORT_TERM_TREND) ) {
      
      int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
      int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);
      
      if(latestDynamicOfAveragesReversalBarShift > 2) {
         
         Print("BULLS DEVIATED at " + getCurrentTime() );
      }
   }*/      
   return;
   
   double zoneUpperLevelCurr = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR);
   double zoneUpperLevelPrev = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
   
   double zoneLowerLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR);
   double zoneLowerLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
   
   //Invalidate SrBands getSrBandsLevel
   double srBandUpperLevelCurr = getSrBandsLevel(SR_BAND_MAIN, CURRENT_BAR); 
   double srBandUpperLevelPrev = getSrBandsLevel(SR_BAND_MAIN, CURRENT_BAR + 1); 
   
   double srBandLowerLevelCurr = getSrBandsLevel(SR_BAND_LOWER, CURRENT_BAR);
   double srBandLowerLevelPrev = getSrBandsLevel(SR_BAND_LOWER, CURRENT_BAR + 1);
   
   //Invalidate MlsBands getMlsBandsLevel
   double mlsBandUpperLevelCurr = getMlsBandsLevel(MLS_BAND_MAIN, CURRENT_BAR); 
   double mlsBandUpperLevelPrev = getMlsBandsLevel(MLS_BAND_MAIN, CURRENT_BAR + 1); 
   
   double mlsBandLowerLevelCurr = getMlsBandsLevel(MLS_BAND_LOWER, CURRENT_BAR);
   double mlsBandLowerLevelPrev = getMlsBandsLevel(MLS_BAND_LOWER, CURRENT_BAR + 1);
         
   //Invalidate Somat3 getSomat3Level
   double somat3Curr = getSomat3Level(SOMAT3_BULLISH_MAIN, CURRENT_BAR); 
   double somat3Prev = getSomat3Level(SOMAT3_BULLISH_MAIN, CURRENT_BAR + 1);      
      
}

//DYNAMIC_MPA Linked

/** END INVALIDATE SIGNALS*/

/** START REVERSALS DETECTIONS*/
/** Start - LINEAR_MA Reversal Detection*/
Reversal getLinearMaReversal() {

   if(checkedBar == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 

   int     length       =  10;  
   double  aFactor      =  3;  
   int     sFactor      =  0;  
   double  gFactor      =  1;  
   double  pctFilter    =  1;
   
   int upTrendBuffer    = 1;
   int downTrendBuffer  = 2; 
   
   if( (getLinearMaLevel(downTrendBuffer, CURRENT_BAR + 1) == EMPTY_VALUE) 
         && (getLinearMaLevel(downTrendBuffer, CURRENT_BAR + 2) == EMPTY_VALUE) ) { //Note that upTrendBuffer is never empty, so we can only rely on downTrendBuffer being empty when testing for up trend
         //Prev 2 was up - atleast minor trend in place, enough to search for reversal 
      
      //currently bullish, look out for bearish reversal
      if( getLinearMaLevel(upTrendBuffer, CURRENT_BAR) == getLinearMaLevel(upTrendBuffer, CURRENT_BAR + 1)) { //It will start by being equal and change as price moves away, thus confirming the reversal
         
         checkedBar = Time[CURRENT_BAR];
         Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME, 0) );
         return BEARISH_REVERSAL;
      }        
   }
   else if( (getLinearMaLevel(downTrendBuffer, CURRENT_BAR + 1) != EMPTY_VALUE) 
         && (getLinearMaLevel(downTrendBuffer, CURRENT_BAR + 2) != EMPTY_VALUE)) { //Prev 2 was up - atleast minor trend in place, enough to search for reversal
   
      //currently bearish, look out for bullish reversal
      if( getLinearMaLevel(downTrendBuffer, CURRENT_BAR) == getLinearMaLevel(downTrendBuffer, CURRENT_BAR + 1)) { //It will start by being equal and change as price moves away, thus confirming the reversal
         
         checkedBar = Time[CURRENT_BAR];
         Print("BULLISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0));
         return BULLISH_REVERSAL;
      }      
   }

   return CONTINUATION;
}
/** Start - LINEAR_MA Reversal Detection*/

/** Start - NOLAG_MA Reversal Detection*/
Reversal getNoLagMaReversal() {

   if(checkedBar == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 

   int     length       =  10;  
   double  aFactor      =  3;  
   int     sFactor      =  0;  
   double  gFactor      =  1;  
   double  pctFilter    =  1;
   
   int upTrendBuffer    = 1;
   int downTrendBuffer  = 2; 
   
   if( (getNoLagMaLevel(upTrendBuffer, CURRENT_BAR + 1) != EMPTY_VALUE) 
         && (getNoLagMaLevel(upTrendBuffer, CURRENT_BAR + 2) != EMPTY_VALUE) ) { //Prev 2 was up - atleast minor trend in place, enough to search for reversal 
      
      //currently bullish, look out for bearish reversal
      if( getNoLagMaLevel(upTrendBuffer, CURRENT_BAR) == getNoLagMaLevel(upTrendBuffer, CURRENT_BAR + 1)) { //It will start by being equal and change as price moves away, thus confirming the reversal
         
         checkedBar = Time[CURRENT_BAR];
         Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
         return BEARISH_REVERSAL;
      }        
   }
   else if( (getNoLagMaLevel(downTrendBuffer, CURRENT_BAR + 1) != EMPTY_VALUE) 
         && (getNoLagMaLevel(downTrendBuffer, CURRENT_BAR + 2) != EMPTY_VALUE)) { //Prev 2 was up - atleast minor trend in place, enough to search for reversal
   
      //currently bearish, look out for bullish reversal
      if( getNoLagMaLevel(downTrendBuffer, CURRENT_BAR) == getNoLagMaLevel(downTrendBuffer, CURRENT_BAR + 1)) { //It will start by being equal and change as price moves away, thus confirming the reversal
         
         checkedBar = Time[CURRENT_BAR];
         Print("BULLISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0));
         return BULLISH_REVERSAL;
      }      
   }

   return CONTINUATION;
}
/** End - NOLAG_MA Reversal Detection*/

/** Start - DONCHIAN_CHANNEL Reversal Detection*/
Reversal getDonchianChannelOverlap() {

   /** Common */
   int timeFrame     = Period(); 
   bool showMiddle   = false;
   bool useClosePrice= false; 
   int donchianChannelUpperBuffer = 0;//Upper
   int donchianChannellowerBuffer = 1;//Lower

   /** Fast DC*/
   int fastChannelPeriod = 3;
   int fastHighLowShift  = 1;
   double fastDonchianChannelUpperLevelCurr = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR); 
   double fastDonchianChannelLowerLevelCurr = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR); 
   double fastDonchianChannelUpperLevelPrev = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR + 1); 
   double fastDonchianChannelLowerLevelPrev = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR + 1); 
      
   /** Slow DC */
   int slowChannelPeriod = 9;       
   int slowHighLowShift  = 0;
   double slowDonchianChannelUpperLevelCurr = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR); 
   double slowDonchianChannelLowerLevelCurr = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR); 
   double slowDonchianChannelUpperLevelPrev = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR + 1); 
   double slowDonchianChannelLowerLevelPrev = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR + 1); 
      
   //Currently BULLISH_TREND - Scan for reversals
   if ( getDynamicPriceZonesAndDonchianChannelReversal() == BEARISH_REVERSAL ) {
   
      //Dynamic Zones upper levels - curr and prev
      double zoneLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR);
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
   
      if( (fastDonchianChannelUpperLevelCurr == slowDonchianChannelUpperLevelCurr) 
            && (fastDonchianChannelUpperLevelPrev == slowDonchianChannelUpperLevelPrev) 
            && (zoneLevelCurr == zoneLevelPrev) ) { //When this scenario happens, Dynamic Zones upper levels are normally flat 
         
         
         if(donchianChannelLatestSignal != SELL_SIGNAL) {
            donchianChannelLatestSignal = SELL_SIGNAL;
            Print("BEARISH REVERSAL on " + getCurrentTime());
         }
      }
      
   }
   
   //Currently BEARISH_TREND - Scan for reversals
   if ( getDynamicPriceZonesAndDonchianChannelReversal() == BULLISH_REVERSAL) {
   
      //Dynamic Zones lower levels - curr and prev
      double zoneLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR);
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);      
   
      if( (fastDonchianChannelLowerLevelCurr == slowDonchianChannelLowerLevelCurr) 
            && (fastDonchianChannelLowerLevelPrev == slowDonchianChannelLowerLevelPrev) 
            && (zoneLevelCurr == zoneLevelPrev) ) { //When this scenario happens, Dynamic Zones lower levels are normally flat 
         
         if(donchianChannelLatestSignal != BUY_SIGNAL) {
            donchianChannelLatestSignal = BUY_SIGNAL;
            Print("BULLISH REVERSAL on " + getCurrentTime());
         }
      }
      
   }   
   
   return CONTINUATION;
}
/** End - DONCHIAN_CHANNEL Reversal Detection*/

/** Start - DONCHIAN_CHANNEL Reversal Detection*/
//TODO
Reversal getDonchianChannelSeBandsReversals() {

   /** Common */
   int timeFrame     = Period(); 
   bool showMiddle   = false;
   bool useClosePrice= false; 
   int donchianChannelUpperBuffer = 0;//Upper
   int donchianChannellowerBuffer = 1;//Lower

   /** Fast DC*/
   int fastChannelPeriod = 3;
   int fastHighLowShift  = 1;
   double fastDonchianChannelUpperLevelCurr = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR); 
   double fastDonchianChannelLowerLevelCurr = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR); 
   double fastDonchianChannelUpperLevelPrev = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR + 1); 
   double fastDonchianChannelLowerLevelPrev = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR + 1); 
      
   /** Slow DC */
   int slowChannelPeriod = 9;       
   int slowHighLowShift  = 0;
   double slowDonchianChannelUpperLevelCurr = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR); 
   double slowDonchianChannelLowerLevelCurr = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR); 
   double slowDonchianChannelUpperLevelPrev = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannelUpperBuffer, CURRENT_BAR + 1); 
   double slowDonchianChannelLowerLevelPrev = getDonchianChannelLevel(timeFrame, slowChannelPeriod, slowHighLowShift, showMiddle, useClosePrice, donchianChannellowerBuffer, CURRENT_BAR + 1); 
      
   //Currently BULLISH_TREND - Scan for reversals
   if ( getDynamicPriceZonesAndDonchianChannelReversal() == BEARISH_REVERSAL ) {
   
      //Dynamic Zones upper levels - curr and prev
      double zoneLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR);
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
   
      if( (fastDonchianChannelUpperLevelCurr == slowDonchianChannelUpperLevelCurr) 
            && (fastDonchianChannelUpperLevelPrev == slowDonchianChannelUpperLevelPrev) 
            && (zoneLevelCurr == zoneLevelPrev) ) { //When this scenario happens, Dynamic Zones upper levels are normally flat 
         
         
         if(donchianChannelLatestSignal != SELL_SIGNAL) {
            donchianChannelLatestSignal = SELL_SIGNAL;
            Print("BEARISH REVERSAL on " + getCurrentTime());
         }
      }
      
   }
   
   //Currently BEARISH_TREND - Scan for reversals
   if ( getDynamicPriceZonesAndDonchianChannelReversal() == BULLISH_REVERSAL) {
   
      //Dynamic Zones lower levels - curr and prev
      double zoneLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR);
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);      
   
      if( (fastDonchianChannelLowerLevelCurr == slowDonchianChannelLowerLevelCurr) 
            && (fastDonchianChannelLowerLevelPrev == slowDonchianChannelLowerLevelPrev) 
            && (zoneLevelCurr == zoneLevelPrev) ) { //When this scenario happens, Dynamic Zones lower levels are normally flat 
         
         if(donchianChannelLatestSignal != BUY_SIGNAL) {
            donchianChannelLatestSignal = BUY_SIGNAL;
            Print("BULLISH REVERSAL on " + getCurrentTime());
         }
      }
      
   }   
   
   return CONTINUATION;
}
/** End - DONCHIAN_CHANNEL Reversal Detection*/

/** One touch of the previous bar(CURRENT_BAR + 1) should be enough to warrant a reversal */
//TODO
Reversal getDynamicPriceZonesAndHurstChannelReversal() { //Hurst 4, 8, 5, 0, 1

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBullishValuePrev  = getJurikFilterLevel(JURIK_FILTER_BULLISH_VALUE, CURRENT_BAR + 1);
      
      if( (jurikFilterBullishValuePrev > zoneLevelPrev)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBearishValuePrev  = getJurikFilterLevel(JURIK_FILTER_BEARISH_VALUE, CURRENT_BAR + 1);
      
      if( (zoneLevelPrev > jurikFilterBearishValuePrev)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}


/** Start - DONCHIAN_CHANNEL Reversal Detection*/
Reversal getDonchianChannelReversal(bool useClosePrice) {

   if(checkedBar == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 
   
   int upperBuffer   = 0;
   int lowerBuffer   = 1; 
   
   
   
   /*if( getDonchianChannelLevel(useClosePrice, upperBuffer, CURRENT_BAR) == getDonchianChannelLevel(useClosePrice, upperBuffer, CURRENT_BAR + 1) ) { 
      
      checkedBar = Time[CURRENT_BAR];
      Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
      return BEARISH_REVERSAL;       
   }
   if( getDonchianChannelLevel(useClosePrice, lowerBuffer, CURRENT_BAR) == getDonchianChannelLevel(useClosePrice, lowerBuffer, CURRENT_BAR + 1) ) { 
   
      checkedBar = Time[CURRENT_BAR];
      Print("BULLISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0));
      return BULLISH_REVERSAL;     
   }*/

   return CONTINUATION;
}
/** End - DONCHIAN_CHANNEL Reversal Detection*/

/** 
  * Start - DYNAMIC_JURIK Reversal Detection - The way this is checked assumes Bullish and Bearish reversal cannot at the same time.
  */
Reversal getDynamicJurikReversal(bool checkCurrentBar) {

   //Only check once per bar
   if(latestDynamicJurikReversalTime == Time[CURRENT_BAR]) {      
      
      return CONTINUATION;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   int previousBarIndex = getPreviousBarIndex(barIndex);
   
   Trend trend = getDynamicJurikTrend();   
   if( trend == BULLISH_TREND ) {
      
      if( getDynamicJuricLevel(DYNAMIC_JURIK_SECOND_UPPER_VALUE, previousBarIndex ) == getDynamicJuricLevel(DYNAMIC_JURIK_SECOND_UPPER_VALUE, barIndex) ) { 
         
         latestDynamicJurikReversalTime = Time[CURRENT_BAR];
         return BEARISH_REVERSAL;       
      }
   }   
   else if( trend == BEARISH_TREND ) {   
      
      if( getDynamicJuricLevel(DYNAMIC_JURIK_SECOND_LOWER_VALUE, previousBarIndex) == getDynamicJuricLevel(DYNAMIC_JURIK_SECOND_LOWER_VALUE, barIndex) ) { 
      
         latestDynamicJurikReversalTime = Time[CURRENT_BAR];
         return BULLISH_REVERSAL;     
      }
   }
   
   return CONTINUATION;
}
/** End - DYNAMIC_MPA Reversal Detection*/


/** 
 *Start - MAIN_STOCH Reversal Detection - Upper and Lower flat can co-incide, so we will depend on DYNAMIC_PRICE_ZONE to give us the current trend
 */
Reversal getMainStochReversal(bool checkCurrentBar) {

   //Only check once per bar
   if(latestMainStochReversalTime == Time[CURRENT_BAR]) {      
      
      return latestMainStochReversal;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   int previousBarIndex = getPreviousBarIndex(barIndex);
   
   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      if( getMainStochLevel(MAIN_STOCH_MAIN_VALUE, previousBarIndex ) == getMainStochLevel(MAIN_STOCH_MAIN_VALUE, barIndex) ) { 
         
         latestMainStochReversal = BEARISH_REVERSAL;
         latestMainStochReversalTime = Time[CURRENT_BAR];
         return BEARISH_REVERSAL;       
      }
   }
   else if( trend == BEARISH_TREND ) {
      
      if( getMainStochLevel(MAIN_STOCH_SECOND_LOWER_VALUE, previousBarIndex ) == getMainStochLevel(MAIN_STOCH_SECOND_LOWER_VALUE, barIndex) ) { 
      
         latestMainStochReversal = BULLISH_REVERSAL;
         latestMainStochReversalTime = Time[CURRENT_BAR];
         return BULLISH_REVERSAL;     
      }
   }   
   return CONTINUATION;
}
/** End - DYNAMIC_MPA Reversal Detection*/

/** 
 *Start - DYNAMIC_MPA Flat Detection - The way this is checked assumes Bullish and Bearish reversal cannot be flat at the same time.
 */
Flatter getDynamicMpaFlatter(int length, bool checkCurrentBar) {

   if(latestDynamicMpaFlatterTime == Time[CURRENT_BAR]) {
      
      return latestDynamicMpaFlatter;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   
    int previousBarIndex = getPreviousBarIndex(barIndex);

   if( (getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, previousBarIndex) == getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex)) ) { 
      
      latestDynamicMpaFlatter = BULLISH_FLATTER;      
      latestDynamicMpaFlatterTime = Time[CURRENT_BAR];
      return BEARISH_FLATTER;       
   }
   else if( (getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, previousBarIndex) == getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex)) ) {
      
      latestDynamicMpaFlatter = BULLISH_FLATTER;
      latestDynamicMpaFlatterTime = Time[CURRENT_BAR];
      return BULLISH_FLATTER;     
   }

   return NO_FLATTER;
}
/** End - DYNAMIC_MPA Reversal Detection*/

/** 
 *Start - DYNAMIC_OF_AVERAGES Flat Detection - The way this is checked assumes Bullish and Bearish reversal cannot at the same time.
 */
Flatter getDynamicOfAveragesFlatter(int length, bool checkCurrentBar) {

   if(latestDynamicOfAveragesFlatterTime == Time[CURRENT_BAR]) {
      
      return latestDynamicOfAveragesFlatter;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   
   int previousBarIndex = getPreviousBarIndex(CURRENT_BAR);
   
   //Signal
   //double dynamicOfAveragesSignalLevelCurr = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR);
   
   //Upper 
   double dynamicOfAveragesUpperLevelCurr  = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SECOND_UPPER, barIndex);
   double dynamicOfAveragesUpperLevelPrev  = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SECOND_UPPER, previousBarIndex);
   
   //Lower 
   double dynamicOfAveragesLowerLevelCurr  = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SECOND_LOWER, barIndex);
   double dynamicOfAveragesLowerLevelPrev  = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SECOND_LOWER, previousBarIndex);   

   if( (dynamicOfAveragesLowerLevelPrev == dynamicOfAveragesLowerLevelCurr ) 
         //&& ( (dynamicOfAveragesSignalLevelCurr > dynamicOfAveragesLowerLevelCurr) ) 
         
         //This is to make sure DynamicOfAverages is currently BEARISH, as it should be before we can expect any BULLISH_REVERSAL reversals
         //&& (getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR ) < getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_MIDDLE, CURRENT_BAR ) )          
         ) { 
      latestDynamicOfAveragesFlatter     = BULLISH_FLATTER;   
      latestDynamicOfAveragesFlatterTime = Time[CURRENT_BAR];
      return BULLISH_FLATTER;     
   }   
   else if( ( dynamicOfAveragesUpperLevelPrev == dynamicOfAveragesUpperLevelCurr) 
         //&& ( (dynamicOfAveragesSignalLevelCurr < dynamicOfAveragesUpperLevelCurr) )
         
         //This is to make sure DynamicOfAverages is currently BULLISH, as it should be before we can expect any BEARISH_REVERSAL reversals 
         //&& (getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR ) > getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_MIDDLE, CURRENT_BAR ) )
         ) { 
      Print("Test");
      latestDynamicOfAveragesFlatter     = BEARISH_FLATTER;
      latestDynamicOfAveragesFlatterTime = Time[CURRENT_BAR];
      return BEARISH_FLATTER;       
   }

   return NO_FLATTER;
}
/** End - DYNAMIC_MPA Reversal Detection*/

/** 
 *Start - DYNAMIC_OF_AVERAGES Signal Detection - The way this is checked assumes Bullish and Bearish reversal cannot at the same time.
 */
Signal getDynamicOfAveragesCrossSignal(int length, bool checkPreviousBar, bool checkFlatOnFastDynamicOfAverages) {

   int fastDynamicOfAveragesLength = 15;
   int slowDynamicOfAveragesLength = 20;
   

   if(latestDynamicOfAveragesCrossSignalTime == Time[CURRENT_BAR]) {
      
      return latestDynamicOfAveragesCrossSignalTime;
   } 

   Cross cross = getDynamicOfAveragesCross(fastDynamicOfAveragesLength, slowDynamicOfAveragesLength, checkPreviousBar);

   if(checkFlatOnFastDynamicOfAverages) { //DYNAMIC_OF_AVERAGES flat must be in place
      
      Flatter flatter = getDynamicOfAveragesFlatter(fastDynamicOfAveragesLength, false); //check previos 2 bars - TODO check if current is check(as it must by default)
      if(flatter == BEARISH_FLATTER) {
      
         if(cross == BULLISH_CROSS) {

            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = Time[CURRENT_BAR];
         }                   
      }
      else if(flatter == BULLISH_FLATTER) {
      
         Cross cross = getDynamicOfAveragesCross(fastDynamicOfAveragesLength, slowDynamicOfAveragesLength, checkPreviousBar);
         if(cross == BEARISH_CROSS) {
            
            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = Time[CURRENT_BAR];
         } 
      }       
        
   }
   else { //DYNAMIC_OF_AVERAGES flat can be ignored
   
         if(cross == BULLISH_CROSS) {

            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = Time[CURRENT_BAR];
         } 
         else if(cross == BEARISH_CROSS) {
            
            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = Time[CURRENT_BAR];
         }

   }

   return NO_SIGNAL;
}
/** End - DYNAMIC_MPA Reversal Detection*/

/** 
 *Start - DYNAMIC_OF_AVERAGES Cross Detection
 */
Cross getDynamicOfAveragesCross(int fastDynamicOfAveragesLength, int slowDynamicOfAveragesLength, bool checkPreviousBar) {

   if(latestDynamicOfAveragesCrossTime == Time[CURRENT_BAR]) {
      
      return latestDynamicOfAveragesCross;
   } 

   if(checkPreviousBar) {
   
      double fastDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(fastDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      double slowDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(slowDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      
      double fastDynamicOfAveragesMiddleLevelPrev = getDynamicOfAveragesLevel(fastDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, getPreviousBarIndex(CURRENT_BAR) );
      double slowDynamicOfAveragesMiddleLevelPrev = getDynamicOfAveragesLevel(slowDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, getPreviousBarIndex(CURRENT_BAR) );
      
      if( (slowDynamicOfAveragesMiddleLevelCurr < fastDynamicOfAveragesMiddleLevelCurr) && (slowDynamicOfAveragesMiddleLevelPrev < fastDynamicOfAveragesMiddleLevelPrev) ) {      
      
         latestDynamicOfAveragesCross = BEARISH_CROSS;
         latestDynamicOfAveragesCrossTime = Time[CURRENT_BAR];
         return BEARISH_CROSS;
      }            
   }
   else {
      
      double fastDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(fastDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      double slowDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(slowDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      
      if( slowDynamicOfAveragesMiddleLevelCurr < fastDynamicOfAveragesMiddleLevelCurr ) {      
      
         latestDynamicOfAveragesCross = BULLISH_CROSS;
         latestDynamicOfAveragesCrossTime = Time[CURRENT_BAR];
         return BEARISH_CROSS;
      }            
   }
   
   return NO_CROSS;
}
/** End - DYNAMIC_OF_AVERAGES Cross Detection*/

/** 
 *Start - JMA_BANDS Reversal Detection - Both higher and lower bands cross at the same time, so it is fine to either check JMA_BANDS_UPPER or JMA_BANDS_LOWER
 */
Reversal getJmaBandsLevelCrossReversal() { 

   int fasterBandsLength = 13;
   int slowerBandsLength = 15;
    
   double pastTwoJmaBandsLevelFaster = getJmaBandsLevel(fasterBandsLength, JMA_BANDS_UPPER, getPastBars(2));
   double pastTwoJmaBandsLevelSlower = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_UPPER, getPastBars(2));
   
   double pastJmaBandsLevelFaster = getJmaBandsLevel(fasterBandsLength, JMA_BANDS_UPPER, getPastBars(1));
   double pastJmaBandsLevelSlower = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_UPPER, getPastBars(1));   
   
   double currJmaBandsLevelFaster = getJmaBandsLevel(fasterBandsLength, JMA_BANDS_UPPER, CURRENT_BAR);
   double currJmaBandsLevelSlower = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_UPPER, CURRENT_BAR);
      
   if( (pastTwoJmaBandsLevelSlower > pastTwoJmaBandsLevelFaster) //It was Bearish
         && (pastJmaBandsLevelFaster > pastJmaBandsLevelSlower)  //It turned Bullish on previous
         && (currJmaBandsLevelFaster > currJmaBandsLevelSlower) ) { //It is currently Bullist
         
      latestJmaBandsReversal     = BULLISH_REVERSAL;   
      latestJmaBandsReversalTime = Time[CURRENT_BAR];
      return BULLISH_REVERSAL;          
   }
   else if( (pastTwoJmaBandsLevelSlower < pastTwoJmaBandsLevelFaster) //It was Bullish
         && (pastJmaBandsLevelFaster < pastJmaBandsLevelSlower)  //It turned Bearish on previous
         && (currJmaBandsLevelFaster < currJmaBandsLevelSlower) ) { //It is currently Bearish
         
      latestJmaBandsReversal     = BEARISH_REVERSAL;   
      latestJmaBandsReversalTime = Time[CURRENT_BAR];
      return BEARISH_REVERSAL;          
   }
  
  
   return CONTINUATION;
}
/** End - JMA_BANDS Reversal Detection*/


/** Start - QUANTILE_BANDS Reversal Detection*/
Reversal getQuantileBandsReversal() {

   if(checkedBar == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 
   
   int upperBuffer   = 0;
   int lowerBuffer   = 3; 
   
   if( getQuantileBandsLevel(upperBuffer, CURRENT_BAR) == getQuantileBandsLevel(upperBuffer, CURRENT_BAR + 1) ) { 
      
      checkedBar = Time[CURRENT_BAR];
      Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
      return BEARISH_REVERSAL;       
   }
   if( getQuantileBandsLevel(lowerBuffer, CURRENT_BAR) == getQuantileBandsLevel(lowerBuffer, CURRENT_BAR + 1) ) { 
   
      checkedBar = Time[CURRENT_BAR];
      Print("BULLISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0));
      return BULLISH_REVERSAL;     
   }

   return CONTINUATION;
}
/** End - QUANTILE_BANDS Reversal Detection*/

/** END REVERSALS DETECTIONS*/

/** START INDICATOR GENERIC LEVELS*/
/** Start - DYNAMIC_PRICE_ZONE Level*/
/**
 * Retrieve the DYNAMIC_PRICE_ZONE given buffer value and barIndex
 *
 * 0 = Lower, never empty
 * 1 = Upper, never empty
 * 2 = Middle, never empty
 */
double getDynamicPriceZonesLevel(int buffer, int barIndex) {
      
   return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_PRICE_ZONE, PRICE_CLOSE, buffer, barIndex), Digits);
}

/** End - DYNAMIC_PRICE_ZONE Level*/

/** Start - DYNAMIC_JURIK Level, trend and slope
 * Retrieve the DYNAMIC_JURIK 
 *
 * 0 = Main(Signal), never empty
 * 1 = Slope, Value=>Bearish, Empty=>Bullish
 * 3 = 2nd Lower, never empty
 * 4 = 1st Lower, never empty
 * 5 = 1st Upper, never empty
 * 6 = 2nd Upper, never empty
 * 7 = Middle, never empty
 */ 
double getDynamicJuricLevel(int buffer, int barIndex) {
   
   int    length           = 10;
   int    dzLookBackBars   = 20;
   bool   showMiddleLine   = false;      
   return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_JURIK, length, dzLookBackBars, showMiddleLine, buffer, barIndex), Digits);
}

Trend getDynamicJurikTrend() {
   
   int previousBarIndex    = getPreviousBarIndex(CURRENT_BAR);
   double priceLevelPrev   = getPreviousPriceClose(previousBarIndex);
   double priceLevelCurr   = iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);   
      
   if( (priceLevelCurr > getDynamicJuricLevel(DYNAMIC_JURIK_MIDDLE_VALUE, CURRENT_BAR)) 
         && (priceLevelPrev > getDynamicJuricLevel(DYNAMIC_JURIK_MIDDLE_VALUE, previousBarIndex))) {
         
         return BULLISH_TREND;
   }
   else if( (priceLevelCurr < getDynamicJuricLevel(DYNAMIC_JURIK_MIDDLE_VALUE, CURRENT_BAR)) 
         && (priceLevelPrev < getDynamicJuricLevel(DYNAMIC_JURIK_MIDDLE_VALUE, previousBarIndex))) {
         
         return BEARISH_TREND;
   }
   
   return NO_TREND;
}

/**
 *  Get the DYNAMIC_JURIK_SLOPE, Buffer 1. EMPY_VALUE => Bullish, !EMPY_VALUE=> Bearish
 */
Slope getDynamicJuricSlope(int barIndex) {

   double slopeValue = getDynamicJuricLevel(DYNAMIC_JURIK_SLOPE_VALUE, barIndex); 
   if(slopeValue != EMPTY_VALUE) {
      
      return BEARISH_SLOPE;
   }
   else {
      
      return BULLISH_SLOPE;
   } 
}
/** End - DYNAMIC_JURIK Level, trend and slope*/

/** Start - MAIN_STOCH Level, trend and slope
 * Retrieve the MAIN_STOCH 
 *
 * 0 = Main(2nd Upper), never empty
 * 1 = 2nd Lower, never empty 
 * 2 = 1st Upper, never empty
 * 3 = 1st Lower, never empty
 * 4 = Signal, never empty
 * 5 = Slope, Value=>Bearish, Empty=>Bullish
 */ 
double getMainStochLevel(int buffer, int barIndex) {
   
   int length              = 20;
   int emaSmoothingPeriod  = 10;
   int channelPeriod       = 10;      
   return NormalizeDouble(iCustom(Symbol(), Period(), MAIN_STOCH, length, emaSmoothingPeriod, channelPeriod, buffer, barIndex), Digits);
}

/**
 *  Get the MAIN_STOCH, Buffer 1. EMPY_VALUE => Bullish, !EMPY_VALUE=> Bearish
 */
Slope getMainStochSlope(int barIndex) {

   double slopeValue = getMainStochLevel(MAIN_STOCH_SLOPE_VALUE, barIndex); 
   if(slopeValue != EMPTY_VALUE) {
      
      return BEARISH_SLOPE;
   }
   else {
      
      return BULLISH_SLOPE;
   } 
}
/** End - MAIN_STOCH Level, trend and slope*/

/** Start - HULL_MA Level*/
/**
 * Retrieve the HULL_MA and slope given length, buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = Up, NOT EMPTY_VALUE even when down trend. Note that upTrendBuffer is never empty, so we can only rely on downTrendBuffer being empty when testing for up trend
 * 2 = Down, EMPTY_VALUE when up trend
 */
double getHullMaLevel(int length, int buffer, int barIndex) {
      
   double pctFilter  = 1; 
   int colorBarBack  = 1;   
   return NormalizeDouble(iCustom(Symbol(), Period(), HULL_MA, length, PRICE_CLOSE, pctFilter, colorBarBack, buffer, barIndex), Digits);
}

Slope getHullMaSlope(int length, int barIndex) {
   
    double hmaMainValuePrev = getHullMaLevel(length, HULL_MA_BULLISH_MAIN, CURRENT_BAR + 1);
    double hmaMainValuePrevPrev = getHullMaLevel(length, HULL_MA_BULLISH_MAIN, CURRENT_BAR + 1);
   
   double hmaBullishValueCurr = getHullMaLevel(length, HULL_MA_BULLISH_VALUE, CURRENT_BAR);
   double hmaBullishValuePrev = getHullMaLevel(length, HULL_MA_BULLISH_VALUE, CURRENT_BAR + 1);
      
   double hmaBearishValueCurr = getHullMaLevel(length, HULL_MA_BEARISH_VALUE, CURRENT_BAR);
   double hmaBearishValuePrev = getHullMaLevel(length, HULL_MA_BEARISH_VALUE, CURRENT_BAR + 1);
   
   if( latestTransitionTime != Time[CURRENT_BAR] ) {
      
      if(hmaMainValuePrev == hmaMainValuePrevPrev) {
         
         Print("Flat @ " + getCurrentTime() );
         
         latestTransitionTime = Time[CURRENT_BAR];
         if( (hmaBullishValuePrev != EMPTY_VALUE) && (hmaBearishValuePrev == EMPTY_VALUE)) {
            
            Print("Slope was Bullish @ " + getTime(CURRENT_BAR + 1) + " and is now... ");
            if( (hmaBullishValueCurr != EMPTY_VALUE) && (hmaBearishValueCurr == EMPTY_VALUE)) { 
            
               Print("...Bullish @ " + getCurrentTime() ); 
            } 
            else if( (hmaBearishValueCurr != EMPTY_VALUE) && (hmaBullishValueCurr != EMPTY_VALUE)) { 
               
               Print("...Bearish @ " + getCurrentTime() );
            }            
         }
         else if( (hmaBearishValuePrev != EMPTY_VALUE) && (hmaBullishValuePrev == EMPTY_VALUE)) {
            
            Print("Slope was Bearish @ " + getTime(CURRENT_BAR + 1) + " and is now... ");
            if( (hmaBullishValueCurr != EMPTY_VALUE) && (hmaBearishValueCurr == EMPTY_VALUE)) { 
            
               Print("...Bullish @ " + getCurrentTime() ); 
            } 
            else if( (hmaBearishValueCurr != EMPTY_VALUE) && (hmaBullishValueCurr != EMPTY_VALUE)) { 
               
               Print("...Bearish @ " + getCurrentTime() );
            }            
         }      
      }
   }

   if( (hmaBullishValueCurr != EMPTY_VALUE) && (hmaBullishValuePrev != EMPTY_VALUE)) { 
   
      return BULLISH_SLOPE; 
   } 
   else if( (hmaBearishValueCurr != EMPTY_VALUE) && (hmaBearishValuePrev != EMPTY_VALUE)) { 
      
      return BEARISH_SLOPE; 
   }
   else {
      
      return UNKNOWN_SLOPE; 
   }

}
/** End - HULL_MA Level and slope*/

/** Start - LINEAR_MA Level*/
/**
 * Retrieve the LINEAR_MA given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = Up, NOT EMPTY_VALUE even when down trend. Note that upTrendBuffer is never empty, so we can only rely on downTrendBuffer being empty when testing for up trend
 * 2 = Down, EMPTY_VALUE when up trend
 */
double getLinearMaLevel(int buffer, int barIndex) {
   
   int length        = 18;     
   int filterPeriod  = 0; 
   double filter     = 2;  
   double filterOn   = 1.0;   
   return NormalizeDouble(iCustom(Symbol(), Period(), LINEAR_MA, length, PRICE_CLOSE, filterPeriod, filter, filterOn, buffer, barIndex), Digits);
}
/** End - LINEAR_MA Level*/

/** Start - NON_LINEAR_KALMAN Level and slope*/
/**
 * Retrieve the NON_LINEAR_KALMAN given buffer value and barIndex
 *
 * 0 = Main(NON_LINEAR_KALMAN_MAIN), never empty
 * 1 = Slope(NON_LINEAR_KALMAN_SLOPE), EMPTY_VALUE = BULLISH, !EMPTY_VALUE = BULLISH
 */
double getNonLinearKalmanLevel(int length, int buffer, int barIndex) {
   
   return NormalizeDouble(iCustom(Symbol(), Period(), NON_LINEAR_KALMAN, length, buffer, barIndex), Digits);
}

Slope getNonLinearKalmanSlope(int length, int barIndex) {
   
   double slope = getNonLinearKalmanLevel(length, NON_LINEAR_KALMAN_SLOPE, barIndex);
   
   if( (slope != EMPTY_VALUE)) {
      
      return BEARISH_SLOPE;
   }
   else {
      
      return BULLISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;
}
/** Start - NON_LINEAR_KALMAN Level and slope*/

/** Start - NOLAG_MA Level*/
/**
 * Retrieve the NOLAG_MA given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = Up, EMPTY_VALUE when down trend
 * 2 = Down, EMPTY_VALUE when up trend
 */
double getNoLagMaLevel(int buffer, int barIndex) {
   
   int     length       =  10;  
   double  aFactor      =  3;  
   int     sFactor      =  0;  
   double  gFactor      =  1;  
   double  pctFilter    =  1;
   return NormalizeDouble(iCustom(Symbol(), Period(), NOLAG_MA, length, PRICE_CLOSE, aFactor, sFactor, gFactor, pctFilter, buffer, barIndex), Digits);
}
/** End - NOLAG_MA Level*/

/** Start - SUPERTREND Level*/
/**
 * Retrieve the SUPERTREND given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = For both Up and down trend
 *   : EMPTY_VALUE=>  Up trend
 *   : NOT EMPTY  =>  Down trend
 */
double getSuperTrendLevel(int buffer, int barIndex) {
   
   int     length       =  1;  
   double  multiplier   =  1;  
   return NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, CURRENT_TIMEFRAME, length, multiplier, buffer, barIndex), Digits);
}
/** End - SUPERTREND Level*/

/** Start - POLIFIT_BANDS Level*/
/**
 * Retrieve the SUPERTREND given buffer value
 *
 * 0 = Main, never empty
 * 1 = For both Up and down trend
 *   : EMPTY_VALUE=>  Up trend
 *   : NOT EMPTY  =>  Down trend
 */
double getSuperTrendLeve_TODO(int buffer, int barIndex) {
   
   int     length       =  1;  
   double  multiplier   =  1;  
   return NormalizeDouble(iCustom(Symbol(), Period(), SUPERTREND, CURRENT_TIMEFRAME, length, multiplier, buffer, barIndex), Digits);
}
/** End - SUPERTREND Level*/

/** Start - NOLAG_MA Level*/
/**
 * Retrieve the SMOOTHED_DIGITAL_FILTER given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 2 = value of the upper MA when MAs are bullish, or value of the lower MA when MAs are bearish
 * 3 = value of the lower MA when MAs are bullish, or value of the upper MA when MAs are bearish
 */
double getSmoothedDigitalFilterLevel(int buffer, int barIndex) {
   
   
   int timeFrame     = Period();
   int    filterType1   = 0; 
   int    filterType2   = 0; 
   double smoothLength  = 10;
   bool   isDoubleSmooth  = true;   
   return NormalizeDouble(iCustom(Symbol(), Period(), SMOOTHED_DIGITAL_FILTER, timeFrame, filterType1, filterType2, smoothLength, isDoubleSmooth, buffer, barIndex), Digits);
}
/** End - SMOOTHED_DIGITAL_FILTER Level*/

/** Start - VOLATILITY_BANDS Level and slope*/
/**
 * Retrieve the VOLATILITY_BANDS given buffer value and barIndex
 *
 * 0 = Main(Middle band) - never empty
 * 3 = value of the upper band -  never empty
 * 4 = value of the lower band -  never empty 
 * 5 = Slope, Upward = 1, Downward = -1 
 */
double getVolitilityBandsLevel(int length, int buffer, int barIndex) {
   
   int timeFrame     = Period();   
   double deviation  = 0.5;   
   return NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, timeFrame, length, deviation, buffer, barIndex), Digits);   
}
/**
 *  Get the VolitilityBands Slope(5). Upward = 1, Downward = -1.
 */
int getVolitilityBandsSlope(int length, int barIndex) {
   
   int slopeBuffer   = 5; 
   return (int)getVolitilityBandsLevel(length, slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
}
/** End - VOLATILITY_BANDS Level and Slope*/

/** Start - BOLLINGER_BANDS Level and Slope*/
/**
 * Retrieve the BOLLINGER_BANDS given buffer value and barIndex. Only retrieve the main band(Middle(0)), and slope(5)
 *
 * 0 = Main, never empty
 * 5 = Slope. Upward = 1, Downward = -1.
 */
double getBollingerBandsLevel(int band, int barIndex) {
   
   int               length            = 10;
   double            deviation         = 1.0;  
   int               deviationType     = 1;
   int               appliedMaMethod   = 4;      
   double            filter            = 1;
   int               FilterPeriod      = 20;
   ENUM_TIMEFRAMES   timeFrame         = PERIOD_CURRENT;
   return NormalizeDouble(iCustom(Symbol(), Period(), BOLLINGER_BANDS, timeFrame, length, deviation, deviationType, appliedMaMethod, filter, FilterPeriod, band, barIndex), Digits);
}

/**
 *  Get the BOLLINGER_BANDS Slope(5). Upward = 1, Downward = -1.
 */
int getBollingerBandsSlope(int barIndex) {
   
   int slopeBuffer   = 5; 
   return (int)getBollingerBandsLevel(slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
}
/** End - BOLLINGER_BANDS Level and Slope */

/** Start - T3_BANDS Level*/
/**
 * Retrieve the T3_BANDS given buffer value and barIndex
 *
 * 0 = Main(T3_BANDS_UPPER_LEVEL) - never empty
 * 1 = value of the middle band(T3_BANDS_MIDDLE_LEVEL)-  never empty
 * 2 = value of the lower band(T3_BANDS_LOWER_LEVEL) -  never empty
 */
double getT3BandsLevel(int band, int barIndex) {
    
   int  length       = 6;
   double hot        = 1;
   double deviation  = 1;   
   bool   original   = false;
   return NormalizeDouble(iCustom(Symbol(), Period(), T3_BANDS, length, deviation, hot, original, band, barIndex), Digits);
}
/** End - T3_BANDS Level*/

/** Start - T3_BANDS_SQUARED Level*/
/**
 * Retrieve the T3_BANDS_SQUARED given buffer value and barIndex
 *
 * 0 = Main(T3_BANDS_UPPER_LEVEL) - never empty
 * 1 = value of the middle band(T3_BANDS_MIDDLE_LEVEL)-  never empty
 * 2 = value of the lower band(T3_BANDS_LOWER_LEVEL) -  never empty
 */
double getT3BandsSquaredLevel(int band, int barIndex) {
    
   int  length       = 10;
   double hot        = 1;  
   bool   original   = false;
   return NormalizeDouble(iCustom(Symbol(), Period(), T3_BANDS_SQUARED, length, hot, original, band, barIndex), Digits);
}
/** End - T3_BANDS_SQUARED Level*/

/** Start - NON_LINEAR_KALMAN_BANDS Level*/
/**
 * Retrieve the NON_LINEAR_KALMAN_BANDS given buffer value and barIndex
 *
 * 0 = NON_LINEAR_KALMAN_BANDS_UPPER;
 * 1 = NON_LINEAR_KALMAN_BANDS_MIDDLE;
 * 2 = NON_LINEAR_KALMAN_BANDS_LOWER;
 */
double getNonLinearKalmanBandsLevel(int filterLength, int band, int barIndex) {

   int               devLength        = filterLength;
   int               preSmooth        = 5;
   int               preSmoothMethod  = 25;
   double            deviation        = 0.5;
   return NormalizeDouble(iCustom(Symbol(), Period(), NON_LINEAR_KALMAN_BANDS, filterLength, devLength, preSmooth, preSmoothMethod, deviation, band, barIndex), Digits);
}
/** End - NON_LINEAR_KALMAN_BANDS Level*/

/** Start - DONCHIAN_CHANNEL Level and slope*/
/**
 * Retrieve the DONCHIAN_CHANNEL given buffer value and barIndex
 *
 * 0 = Main(Upper), never empty
 * 1 = Lower band
 * 2 = Middle
 * 4 = Slope
 */
double getDonchianChannelLevel(int timeFrame, int length, int highLowShift, bool showMiddle, bool useClosePrice, int buffer, int barIndex) {
   
   return NormalizeDouble(iCustom(Symbol(), Period(), DONCHIAN_CHANNEL, timeFrame, length, highLowShift, showMiddle, useClosePrice, buffer, barIndex), Digits);
}
/**
 *  Get the DONCHIAN_CHANNEL Slope(5). Upward = 1, Downward = -1.
 */
int getDonchianChannelSlope(int barIndex) {
   
   int slopeBuffer   = 4; 
   return 0;//(int)getDonchianChannelLevel(false, slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
}
/** End - DONCHIAN_CHANNEL Level and slope*/

/** Start - SE_BANDS Level*/
/**
 * Retrieve the SE_BANDS given buffer value and barIndex
 *
 * 0 = Main(Middle), never empty
 * 1 = Upper band
 * 2 = Lower
 */
double getSeBandsLevel(int buffer, int barIndex) {
   
   int timeFrame              = Period(); 
   int smoothingLength        = 3;
   int linearRegresionPeriod  = 15;
   return NormalizeDouble(iCustom(Symbol(), Period(), SE_BANDS, timeFrame, linearRegresionPeriod, smoothingLength, buffer, barIndex), Digits);
}
/** End - SE_BANDS Level*/

/** Start - QUANTILE_BANDS Level*/
/**
 * Retrieve the QUANTILE_BANDS given buffer value and barIndex
 *
 * 0 = Main(Upper), never empty
 * 3 = Lower
 */
double getQuantileBandsLevel(int buffer, int barIndex) {
   
   int timeFrame  = Period(); 
   int length     = 10;
   return NormalizeDouble(iCustom(Symbol(), Period(), QUANTILE_BANDS, timeFrame, length, buffer, barIndex), Digits);
}
/** End - SE_BANDS Level*/

/** Start - SOMAT3 Level and slope*/
/**
 * Retrieve the SOMAT3 given buffer value and barIndex
 *
 * 0 = Main(slope), Never empty. 1 = > Bullish, -1 => Bearish.
 * 1 = Bullish value, Never empty
 * 2 = Bearish value, empty when in Mullish mode
 */
double getSomat3Level(int buffer, int barIndex) {
   
   int timeFrame              = Period(); 
   int length                 = 10;
   double sensitivityFactor_  = 0.4;
   return NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, timeFrame, length, sensitivityFactor_, buffer, CURRENT_BAR), Digits);
}
/**
 *  Get the SOMAT3 Slope(5). Upward = 1, Downward = -1.
 */
int getSomat3Slope(int barIndex) {
   
   int slopeBuffer   = 0; 
   return (int)getSomat3Level(slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
}
/** End - SOMAT3 Level and slope*/

/** Start - DYNAMIC_OF_AVERAGES Level */
/**
 * Retrieve the DYNAMIC_OF_AVERAGES given buffer value and barIndex
 *
 * 0 = Main(DYNAMIC_OF_AVAERAGES_SIGNAL)
 * 1 = DYNAMIC_OF_AVAERAGES_SECOND_LOWER 
 * 2 = DYNAMIC_OF_AVAERAGES_FIRST_LOWER  
 * 3 = DYNAMIC_OF_AVAERAGES_FIRST_UPPER  
 * 4 = DYNAMIC_OF_AVAERAGES_SECOND_UPPER
 * 5 = DYNAMIC_OF_AVAERAGES_MIDDLE
 */
double getDynamicOfAveragesLevel(int length, int buffer, int barIndex) {

   //Only check once per bar
   if(latestDynamicOfAveragesShortTermTrendTime == Time[CURRENT_BAR]) {      
      
      return latestDynamicOfAveragesShortTermTrend;
   } 
             
   int method     =  8; 
   int dzLookBack =  12;
   ENUM_APPLIED_PRICE price = PRICE_CLOSE;
   return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVERAGES, length, method, dzLookBack, buffer, barIndex), Digits);
}

Trend getDynamicOfAveragesShortTermTrend(int length) {//IDEA: Invalidate trends, closing trades

   double midLevelCurr = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_MIDDLE, CURRENT_BAR);
   double midLevelPrev = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_MIDDLE, getPreviousBarIndex(CURRENT_BAR));
   
   double signalCurr = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR);
   double signalPrev = getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SIGNAL, getPreviousBarIndex(CURRENT_BAR));      

   if( ((latestDynamicOfAveragesShortTermTrend != BULLISH_SHORT_TERM_TREND) 
         && (signalCurr > midLevelCurr ) && (signalCurr > midLevelPrev)) ) {
   
      latestDynamicOfAveragesShortTermTrend = BULLISH_SHORT_TERM_TREND;
      latestDynamicOfAveragesShortTermTrendTime = Time[CURRENT_BAR];    
      return BULLISH_SHORT_TERM_TREND;
   }
   else if( (latestDynamicOfAveragesShortTermTrend != BEARISH_SHORT_TERM_TREND) 
         && ((signalCurr < midLevelCurr ) && (signalCurr < midLevelPrev)) ) {
      
      latestDynamicOfAveragesShortTermTrend = BEARISH_SHORT_TERM_TREND;
      latestDynamicOfAveragesShortTermTrendTime = Time[CURRENT_BAR];       
      return BEARISH_SHORT_TERM_TREND;
   }
   
   return NO_TREND;
}
/** End - DYNAMIC_OF_AVERAGES Level*/

/** Start - DYNAMIC_MPA Level */
/**
 * Retrieve the DYNAMIC_MPA given buffer value and barIndex
 *
 * 0 = Main(Upper line)
 * 2 = Middle line
 * 4 = Lower line
 * 5 = Signal line
 */
double getDynamicMpaLevel(int length, int buffer, int barIndex) {
   
   int method     =  10; 
   int dzLookBack =  5;
   ENUM_APPLIED_PRICE price = PRICE_CLOSE;
   return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_MPA, length, price, method, dzLookBack, buffer, barIndex), Digits);
}
/** End - DYNAMIC_MPA Level*/

/** Start - JURIK_FILTER Level and slope*/
/**
 * Retrieve the JURIK_FILTER given buffer value and barIndex
 *
 * 0 = Main(Bullish), Never empty.
 * 1 = Bearish value, Empty when Bullish
 * 5 = Slope. Upward = 1, Downward = -1.
 */
double getJurikFilterLevel(int buffer, int barIndex) {
   
   int timeFrame  =  Period(); 
   int length     =  15;
   double phase   =  100;             
   int price      =  21; //Zero based, pr_hatbiased2;    
   double filter  =  1; 
   int filterType =  2; //Apply filter to all
   
   return NormalizeDouble(iCustom(Symbol(), Period(), JURIK_FILTER, timeFrame, length, phase, price, filter, filterType, buffer, barIndex), Digits);
}
/**
 *  Get the JURIK_FILTER Slope(5). Upward = 1, Downward = -1.
 */
Slope getJurikFilterSlope(int barIndex) {

   int slope = (int)getJurikFilterLevel(JURIK_FILTER_SLOPE, barIndex);//It is safe to explictly cast to int as the slope is either Upward = 1, or Downward = -1.
   if(slope == 1) {

      return BULLISH_SLOPE;
   }
   else if(slope == -1){
      
      return BEARISH_SLOPE;
   }
   else {
      
      return UNKNOWN_SLOPE;
   }
}
/** End - JURIK_FILTER Level and slope*/

/** Start - MLS_BANDS Level*/
/**
 * Retrieve the MLS_BANDS given buffer value and barIndex
 *
 * 0 = Main(Upper Band), Never empty.
 * 1 = lower Band, Never empty
 */
double getMlsBandsLevel(int buffer, int barIndex) {
   
   int length   = 10;
   int shift      = 0;
   int future     = 0;
   bool calculateDeflection= false;
   bool reDraw = true; 
   return NormalizeDouble(iCustom(Symbol(), Period(), MLS_BANDS, length, shift, future, calculateDeflection, reDraw, buffer, barIndex), Digits);
}
/** End - MLS_BANDS Level*/

/** Start - SR_BANDS Level and slope*/
/**
 * Retrieve the SR_BANDS given buffer value and barIndex
 *
 * 0 = Main(Upper Band), Never empty.
 * 1 = lower Band, Never empty
 * 2 = Bullish Slope. Empty when Bearish.
 * 3 = Bearish Slope. Empty when Bullish. 
 */
double getSrBandsLevel(int buffer, int barIndex) {
   
   int range =  5;
   return NormalizeDouble(iCustom(Symbol(), Period(), SR_BANDS, range, buffer, barIndex), Digits);
}
/**
 *  Get the SR_BANDS Slope(5). Upward = 1, Downward = -1.
 */
Slope getSrBandsSlope(int barIndex) {

   double bullishSlope = getSrBandsLevel(SR_BULLISH_SLOPE, barIndex);
   double bearishSlope = getSrBandsLevel(SR_BEARISH_SLOPE, barIndex);
   
   if( (bullishSlope != EMPTY_VALUE) && (bearishSlope == EMPTY_VALUE) ) {
      
      return BULLISH_SLOPE;
   }
   else if( (bearishSlope != EMPTY_VALUE) && (bullishSlope == EMPTY_VALUE) ) {
      
      return BEARISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;
}
/** End - SR_BANDS Level and slope*/

/** Start - JMA_BANDS Level*/
/**
 * Retrieve the JMA_BANDS given price, buffer value and barIndex
 *
 * 0 = Upper band, never empty
 * 1 = Lower band, never empty
 */
double getJmaBandsLevel(int length, int buffer, int barIndex) {
   
   double deviation     = 0.1; //Day 0.5;     
   return NormalizeDouble(iCustom(Symbol(), Period(), JMA_BANDS, length, deviation, buffer, barIndex), Digits);
}
/** End - JURIC_FILTER Level*/

/** Start - EFT Level*/
/**
 * Retrieve the EFT given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = Empty when bullish, not empty when bearish 
 * 3 = Never empty
 * 
 * Application: if Buffer0 > Buffer3 => Bullish, if Buffer3 > Buffer0 => Bearish
 * Oversold/Overbought Levels: 6-7, (-7)-(-6)
 */
double getEftLevel(int buffer, int barIndex) {
   
   int length        = 10;         
   double weight     = 1.5;               
   double filter     = 1;                 
   int filterPeriod  = 1;                 
   int applyFilterTo = 2;            
   return NormalizeDouble(iCustom(Symbol(), Period(), EFT, length, weight, filter, filterPeriod, applyFilterTo, buffer, barIndex), Digits);
}
/** End - EFT Level*/

/** Start - FIBO_BANDS Level and slope*/
/**
 * Retrieve the FIBO_BANDS given buffer value and barIndex
 *
 * 0 = Main(Upper), never empty
 * 1 = Lower band
 * 2 = Middle
 * 4 = Slope
 */
double getFiboBandsLevel_TODO(int buffer, int barIndex) {
   
   int timeFrame        = Period(); 
   int channelPeriod   = 10;
   int highLowShift    = 1;
   bool showMiddle      = true;
   bool useClosePrice   = false;
   return NormalizeDouble(iCustom(Symbol(), Period(), FIBO_BANDS, timeFrame, channelPeriod, highLowShift, showMiddle, useClosePrice, buffer, barIndex), Digits);
}
/**
 *  Get the FIBO_BANDS Slope(5). Upward = 1, Downward = -1.
 */
int getFiboBandsLevelSlope_TODO(int barIndex) {
   
   int slopeBuffer   = 4; 
   return 0;//(int)getDonchianChannelLevel(false, slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
}
/** End - FIBO_BANDS Level and slope*/

/** END INDICATOR GENERIC LEVELS*/


//TODO 27/06/2018
//VOLATILITY_BANDS
//POLYFIT_BANDS
//DIMPA
//Half Trend Channel Goes out of Price Zones. Reversal is eminent
//-Indicator blip-bloop
// MA(5) LW High/Low



/** END NOLAG_MA REVERSALS DETECTIONS*/

/*End: NOLAG_MA Setup */

//HMA 20 or 10 (Same as SDL), Use HMA as SDL "repaints sometimes"
// - Slope detecor, Stop Loss - Use HMA for Slope detection
// - Exits

//Non-Lag 7.9 - Back in, 

//SuperTrend nrp mtf - NB Price encapsulator
//Polifit
//HiLo
//TriggerLines 

//PhD Stepped Stoch, Levels 5, 95. Can be used for momentum
//PhD SOMAT 3(10, 0.4) and Buzzer(10) Cross. 
//Buzzer - Apparently is a Price Channel version with sinc smoothing(and this makes the values asymetric and are not predictable) which is not done properly by something who doesnt understand the concept - TudorGirl(Banned from FF).



void smoothedDigitalFilterLevelTest() {
   
   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   double upper = getQuantileBandsLevel(0, 0); 
   double lower = getQuantileBandsLevel(4, 0);
   
   double upperPrev = getQuantileBandsLevel(0, 1); 
   double lowerPrev = getQuantileBandsLevel(4, 1);   
   
   if(upperPrev == upper) {
      
      Print("UPPER BANDS ARE FLAT at: " + (string)Time[CURRENT_BAR]);
   }
   else if(lowerPrev == lower) {
      
      Print("LOWER BANDS ARE FLAT at: " + (string)Time[CURRENT_BAR]);
   }   
}

void getSomat3LevelTest() {
   
   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   double slope = getSomat3Slope(0); 
   double main = getSomat3Level(1, 0);
   double lower = getSomat3Level(2, 0);
   Print("Main value: " + (string)main);
   
   if(slope == 1) {
        
      Print("Bullish at: " + (string)Time[CURRENT_BAR]);
   }
   else if(slope == -1) {
      
      Print("Bearish at: " + (string)Time[CURRENT_BAR]);
   }   
}

/** START TRANSITION DETECTIONS */
/** START DYNAMIC_JURIK */
/** 
 * Only check if previous volitilityBandsLevel was outside dynamicMpaLevel and is now inside. 
 * When this happens, the dynamicMpaLevel should atleast have been flat for current and previous level, getDynamicMpaFlatter(true)
 */
 //TODO: CHANGE getDynamicMpaLevel to getDynamicJuricLevel
Transition getDynamicJurikAndVolitilityBandsTransition(bool checkCurrentBar) {

   int length = 20;
   int volitilityLength = 20;
   Reversal rev = getDynamicJurikReversal(true);
   
   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }   
   
   int previousBarIndex = getPreviousBarIndex(barIndex);
   
   if(rev == BEARISH_REVERSAL) {
      
      //DYNAMIC_MPA
      double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, previousBarIndex);      
      //VOLATILITY_BANDS      
      double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
      double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, previousBarIndex);
      
      if( (volitilityBandsLevelPrev > dynamicMpaLevelPrev) && (dynamicMpaLevelCurr > volitilityBandsLevelCurr ) ) {
         
         return BULLISH_TO_BEARISH_TRANSITION;
      }
      
   }
   else if(rev == BULLISH_REVERSAL) { 
     
      //DYNAMIC_MPA
      double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, previousBarIndex);
      //VOLATILITY_BANDS      
      double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
      double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, previousBarIndex);
      
      if( ( dynamicMpaLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicMpaLevelCurr) ) {
         
         return BEARISH_TO_BULLISH_TRANSITION;
      }   
   }
   else {
         
         //Scan for suddent reversal - A cross of DYNAMIC_MPA and VOLATILITY_BANDS without the DYNAMIC_MPA flattening first
         
         //DYNAMIC_MPA
         double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
         double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, previousBarIndex);
         //VOLATILITY_BANDS      
         double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
         double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, previousBarIndex);
         if( (volitilityBandsLevelPrev > dynamicMpaLevelPrev) && (dynamicMpaLevelCurr > volitilityBandsLevelCurr ) ) {
         
            return SUDDEN_BULLISH_TO_BEARISH_TRANSITION;
         }
         
         //DYNAMIC_MPA
         dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);
         dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, previousBarIndex);
         //VOLATILITY_BANDS      
         volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
         volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, previousBarIndex);
         if( ( dynamicMpaLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicMpaLevelCurr) ) {
         
            return SUDDEN_BEARISH_TO_BULLISH_TRANSITION;
         }          
                  
   }
   
   return NO_TRANSITION;
}
/** END DYNAMIC_JURIK TRANSITION DETECTIONS */

/** 
 * Only check if previous volitilityBandsLevel was outside dynamicMpaLevel and is now inside. 
 * When this happens, the dynamicMpaLevel should atleast have been flat for current and previous level, getDynamicMpaFlatter(true)
 */
Transition getDynamicMpaAndVolitilityBandsReversal(int length, int volitilityLength, bool checkCurrentBar, bool checkPreviousVolitilityBandsLevels) {

   Flatter flatter = getDynamicMpaFlatter(20, checkCurrentBar);
   
   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }   
   
   int previousBarIndex = getPreviousBarIndex(barIndex);
   
   if(flatter == BEARISH_FLATTER) {
      
      //DYNAMIC_MPA
      double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, previousBarIndex);      
      
      //VOLATILITY_BANDS      
      double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
      double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, previousBarIndex);
      
      if(checkPreviousVolitilityBandsLevels) { //Check previous VolitilityBandsLevels
      
         if( (volitilityBandsLevelPrev > dynamicMpaLevelPrev) && (dynamicMpaLevelCurr > volitilityBandsLevelCurr ) ) {
            
            return BULLISH_TO_BEARISH_TRANSITION;
         }
      }
      else {// Dont check previous VolitilityBandsLevels
         
         if(dynamicMpaLevelCurr > volitilityBandsLevelCurr) {
            
            return BULLISH_TO_BEARISH_TRANSITION;
         }      
      }
      
   }
   else if(flatter == BULLISH_FLATTER) { 
     
      //DYNAMIC_MPA
      double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, previousBarIndex);
      
      //VOLATILITY_BANDS      
      double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
      double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, previousBarIndex);
      
      if(checkPreviousVolitilityBandsLevels) { //Check previous VolitilityBandsLevels
         
         if( ( dynamicMpaLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicMpaLevelCurr) ) {
            
            return BEARISH_TO_BULLISH_TRANSITION;
         } 
      } 
      else { // Dont check previous VolitilityBandsLevels
         
         if( volitilityBandsLevelCurr > dynamicMpaLevelCurr ) {
            
            return BEARISH_TO_BULLISH_TRANSITION;
         }       
      } 
   }
   else {
         
         //Scan for suddent reversal - A cross of DYNAMIC_MPA and VOLATILITY_BANDS without the DYNAMIC_MPA flattening first
         
          /*--BULLISH_TO_BEARISH--*/
         //DYNAMIC_MPA
         double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
         double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, previousBarIndex);
         
         //VOLATILITY_BANDS      
         double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
         double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, previousBarIndex);
         
         if(checkPreviousVolitilityBandsLevels) { //Check previous VolitilityBandsLevels
            
            if( (volitilityBandsLevelPrev > dynamicMpaLevelPrev) && (dynamicMpaLevelCurr > volitilityBandsLevelCurr ) ) {
            
               return SUDDEN_BULLISH_TO_BEARISH_TRANSITION;
            }
         }
         else { // Dont check previous VolitilityBandsLevels
            
            if( dynamicMpaLevelCurr > volitilityBandsLevelCurr ) {
            
               return SUDDEN_BULLISH_TO_BEARISH_TRANSITION;
            }         
         }
         
         /*--BEARISH_TO_BULLISH--*/
         //DYNAMIC_MPA
         dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);
         dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, previousBarIndex);
         
         //VOLATILITY_BANDS      
         volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
         volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, previousBarIndex);
         
         if(checkPreviousVolitilityBandsLevels) { //Check previous VolitilityBandsLevels
            
            if( ( dynamicMpaLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicMpaLevelCurr) ) {
            
               return SUDDEN_BEARISH_TO_BULLISH_TRANSITION;
            } 
         } 
         else { // Dont check previous VolitilityBandsLevels
            if( ( dynamicMpaLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicMpaLevelCurr) ) {
            
               return SUDDEN_BEARISH_TO_BULLISH_TRANSITION;
            }         
         }                
   }
   
   return NO_TRANSITION;
}
/** END TRANSITION DETECTIONS */

/** 
 * Only check if previous volitilityBandsLevel was outside dynamicMpaLevel and is now inside. 
 * When this happens, the dynamicMpaLevel should atleast have been flat for current and previous level, getDynamicMpaFlatter(true)
 */
Transition getDynamicOfAveragesAndVolitilityBandsTransition(int volitilityLength, bool checkCurrentBar) {

   int dynamicOfAveragesLength = 15;
   Flatter flatter = getDynamicOfAveragesFlatter(dynamicOfAveragesLength, false);
   
   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }   
   
   int previousBarIndex = getPreviousBarIndex(barIndex);
   
   if(flatter == BEARISH_FLATTER) {
      
      //DYNAMIC_OF_AVAERAGES
      double dynamicOfAveragesLevelCurr = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_UPPER, barIndex);
      double dynamicOfAveragesLevelPrev = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_UPPER, previousBarIndex);      
      
      //VOLATILITY_BANDS      
      double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
      double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, previousBarIndex);
      
      if( (volitilityBandsLevelPrev > dynamicOfAveragesLevelPrev) && (dynamicOfAveragesLevelCurr > volitilityBandsLevelCurr ) ) {
         
         return BULLISH_TO_BEARISH_TRANSITION;
      }
      
   }
   else if(flatter == BULLISH_FLATTER) { 
     
      //DYNAMIC_OF_AVAERAGES
      double dynamicOfAveragesLevelCurr = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_LOWER, barIndex);
      double dynamicOfAveragesLevelPrev = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_LOWER, previousBarIndex);
      
      //VOLATILITY_BANDS      
      double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
      double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, previousBarIndex);
      
      if( ( dynamicOfAveragesLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicOfAveragesLevelCurr) ) {
         
         return BEARISH_TO_BULLISH_TRANSITION;
      }   
   }
   else {
         
         //Scan for suddent reversal - A cross of DYNAMIC_OF_AVAERAGES and VOLATILITY_BANDS without the DYNAMIC_OF_AVAERAGES flattening first
         
         //DYNAMIC_OF_AVAERAGES
         double dynamicOfAveragesLevelCurr = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_UPPER, barIndex);
         double dynamicOfAveragesLevelPrev = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_UPPER, previousBarIndex);
         
         //VOLATILITY_BANDS      
         double volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
         double volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, previousBarIndex);
         if( (volitilityBandsLevelPrev > dynamicOfAveragesLevelPrev) && (dynamicOfAveragesLevelCurr > volitilityBandsLevelCurr ) ) {
         
            return SUDDEN_BULLISH_TO_BEARISH_TRANSITION;
         }
         
         //DYNAMIC_OF_AVAERAGES
         dynamicOfAveragesLevelCurr = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_LOWER, barIndex);
         dynamicOfAveragesLevelPrev = getDynamicOfAveragesLevel(dynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SECOND_LOWER, previousBarIndex);
         
         //VOLATILITY_BANDS      
         volitilityBandsLevelCurr = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
         volitilityBandsLevelPrev = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, previousBarIndex);
         if( ( dynamicOfAveragesLevelPrev > volitilityBandsLevelPrev) && (volitilityBandsLevelCurr > dynamicOfAveragesLevelCurr) ) {
         
            return SUDDEN_BEARISH_TO_BULLISH_TRANSITION;
         }          
                  
   }
   
   return NO_TRANSITION;
}
/** END TRANSITION DETECTIONS */

/** START REVERSAL DETECTIONS */
Reversal getT3OuterBandsReversal(bool checkCurrentBar) {

   if(latestT3OuterBandsReversalTime == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   
   int previousBarIndex = getPreviousBarIndex(barIndex);     
   
   double t3BandLevelCurr = 0.0;  
   double t3BandLevelPrev = 0.0;
   double t3BandSquaredLevelCurr = 0.0;
   double t3BandSquaredLevelPrev = 0.0;   
   
   Trend trend = getDynamicPriceZonesTrend();   
   //if( trend == BULLISH_TREND ) {
   
      //T3_BANDS
      t3BandLevelCurr  = getT3BandsLevel(T3_BANDS_UPPER_LEVEL, CURRENT_BAR);
      t3BandLevelPrev  = getT3BandsLevel(T3_BANDS_UPPER_LEVEL, previousBarIndex);
      
      //T3_BANDS_SQUARED
      t3BandSquaredLevelCurr  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_UPPER_LEVEL, CURRENT_BAR);
      t3BandSquaredLevelPrev  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_UPPER_LEVEL, previousBarIndex);
      
      if( (latestT3OuterBandsReversal != BEARISH_REVERSAL) // Ignore, already BEARISH_REVERSAL
            && (t3BandSquaredLevelCurr > t3BandLevelCurr) && (t3BandSquaredLevelPrev > t3BandLevelPrev)) {
         
         latestT3OuterBandsReversal = BEARISH_REVERSAL;
         latestT3OuterBandsReversalTime = Time[CURRENT_BAR];         
         return BEARISH_REVERSAL;
      }      
   //}
   //else if( trend == BEARISH_TREND ) {
      
      //T3_BANDS
      t3BandLevelCurr  = getT3BandsLevel(T3_BANDS_LOWER_LEVEL, CURRENT_BAR);
      t3BandLevelPrev  = getT3BandsLevel(T3_BANDS_LOWER_LEVEL, previousBarIndex);
      
      //T3_BANDS_SQUARED
      t3BandSquaredLevelCurr  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_LOWER_LEVEL, CURRENT_BAR);
      t3BandSquaredLevelPrev  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_LOWER_LEVEL, previousBarIndex);
      
      if( (latestT3OuterBandsReversal != BULLISH_REVERSAL) // Ignore, already BULLISH_REVERSAL
             &&(t3BandSquaredLevelCurr < t3BandLevelCurr) && (t3BandSquaredLevelPrev < t3BandLevelPrev)) {
         
         latestT3OuterBandsReversal = BULLISH_REVERSAL;
         latestT3OuterBandsReversalTime = Time[CURRENT_BAR];
         return BULLISH_REVERSAL;
      }      
   //}
   
   return CONTINUATION;          
}

/** START REVERSAL DETECTIONS */
Reversal getT3MiddleBandsReversal(bool checkCurrentBar) {

   if(latestT3MiddleBandsReversalTime == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   
   int previousBarIndex = getPreviousBarIndex(barIndex);      
   
   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
   
      //T3_BANDS
      double t3BandLevelCurr  = getT3BandsLevel(T3_BANDS_MIDDLE_LEVEL, CURRENT_BAR);
      double t3BandLevelPrev  = getT3BandsLevel(T3_BANDS_MIDDLE_LEVEL, previousBarIndex);
      
      //T3_BANDS_SQUARED
      double t3BandSquaredLevelCurr  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_MIDDLE_LEVEL, CURRENT_BAR);
      double t3BandSquaredLevelPrev  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_MIDDLE_LEVEL, previousBarIndex);
      
      if( (latestT3MiddleBandsReversal != BEARISH_REVERSAL) // Ignore, already BEARISH_REVERSAL
            && (t3BandSquaredLevelCurr > t3BandLevelCurr) && (t3BandSquaredLevelPrev > t3BandLevelPrev)) {
         
         latestT3MiddleBandsReversal = BEARISH_REVERSAL;
         latestT3MiddleBandsReversalTime = Time[CURRENT_BAR];
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //T3_BANDS
      double t3BandLevelCurr  = getT3BandsLevel(T3_BANDS_MIDDLE_LEVEL, CURRENT_BAR);
      double t3BandLevelPrev  = getT3BandsLevel(T3_BANDS_MIDDLE_LEVEL, previousBarIndex);
      
      //T3_BANDS_SQUARED
      double t3BandSquaredLevelCurr  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_MIDDLE_LEVEL, CURRENT_BAR);
      double t3BandSquaredLevelPrev  = getT3BandsSquaredLevel(T3_BANDS_SQUARED_MIDDLE_LEVEL, previousBarIndex);
      
      if( (latestT3MiddleBandsReversal != BULLISH_REVERSAL) // Ignore, already BULLISH_REVERSAL 
            && (t3BandSquaredLevelCurr < t3BandLevelCurr) && (t3BandSquaredLevelPrev < t3BandLevelPrev)) {
         
         latestT3MiddleBandsReversal = BULLISH_REVERSAL;
         latestT3MiddleBandsReversalTime = Time[CURRENT_BAR];
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;
}

Reversal getDynamicPriceZonesAndJurikFilterReversal() {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBullishValuePrev  = getJurikFilterLevel(JURIK_FILTER_BULLISH_VALUE, CURRENT_BAR + 1);
      
      if( (jurikFilterBullishValuePrev > zoneLevelPrev)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBearishValuePrev  = getJurikFilterLevel(JURIK_FILTER_BEARISH_VALUE, CURRENT_BAR + 1);
      
      if( (zoneLevelPrev > jurikFilterBearishValuePrev)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesandDynamicMpaReversal(int length, int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      //DIMPA
      double dynamicMpaUpperLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(length, DYNAMIC_MPA_SIGNAL, barIndex);
      
      if( (dynamicMpaUpperLevel > zoneLevelPrev) && (dynamicMpaSignalLevel > zoneLevelPrev) ) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      //DIMPA
      double dynamicMpaLowerLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);  
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(length, DYNAMIC_MPA_SIGNAL, barIndex);    
      
      if( (dynamicMpaLowerLevel < zoneLevelPrev) && (dynamicMpaSignalLevel < zoneLevelPrev) ) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesandJmaBandsReversal(int barIndex) {//This will use the getJmaBandsLevelCrossReversal to detect strong reversal

   int slowerBandsLength = 15;

   //DYNAMIC_PRICE_ZONE Trend 
   Trend trend = getDynamicPriceZonesTrend(); 
   
   //JMA_BANDS Reversal
   Reversal rev = getJmaBandsLevelCrossReversal();
     
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //JMA_BANDS
      double pastJmaBandsLevel = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_UPPER, getPastBars(1));    
      double pastTwoJmaBandsLevel = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_UPPER, getPastBars(2));  
      
      if( (zoneLevelPrev < pastJmaBandsLevel) && (zoneLevelPrev < pastTwoJmaBandsLevel) ) {
         
         // JMA_BANDS are outside DYNAMIC_PRICE_ZONE, wait for JMA_BANDS bearish Reversal
         if(rev == BEARISH_REVERSAL) {
            
            latestDynamicPriceZonesandJmaBandsReversal = BEARISH_REVERSAL;
            latestDynamicPriceZonesandJmaBandsReversalTime = Time[CURRENT_BAR];            
            return BEARISH_REVERSAL;
         }                   
      }       
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //JMA_BANDS
      double pastJmaBandsLevel = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_LOWER, getPastBars(1));
      double pastTwoJmaBandsLevel = getJmaBandsLevel(slowerBandsLength, JMA_BANDS_LOWER, getPastBars(2));   
      
      if( (zoneLevelPrev > pastJmaBandsLevel) && (zoneLevelPrev > pastTwoJmaBandsLevel) ) {
         
         // JMA_BANDS are outside DYNAMIC_PRICE_ZONE, wait for JMA_BANDS bullish Reversal
         if(rev == BULLISH_REVERSAL) {
            
            latestDynamicPriceZonesandJmaBandsReversal = BULLISH_REVERSAL;
            latestDynamicPriceZonesandJmaBandsReversalTime = Time[CURRENT_BAR];             
            return BULLISH_REVERSAL;
         }         
      }
     
   }
   
   return CONTINUATION;      
}


Reversal getDynamicPriceZonesAndMlsBandsReversal(int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      //MLS_BANDS
      double mlsBandsLevelUpperLevel   = getMlsBandsLevel(MLS_BAND_MAIN, barIndex);
      
      if( (mlsBandsLevelUpperLevel > zoneLevelPrev)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      //MLS_BANDS
      double mlsBandsLevelLowerLevel   = getMlsBandsLevel(MLS_BAND_LOWER, barIndex);   
      
      if( (mlsBandsLevelLowerLevel < zoneLevelPrev) ) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getNonLinearKalmanReversal(int nonLinearKalmanLength, bool checkCurrentBar) {

   if(latestNonLinearKalmanSlopeTime == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 

   int barIndex = 0;
   if(checkCurrentBar) { // Option to check if current bar must be checked. If checkCurrentBar is true, current and the previous bars will be checked, 
                         // Otherwise the previous 2 bars will checked without checking the current bar - this is more safe as the reversal is comfirmed - but a bit late! 
      barIndex = CURRENT_BAR;
   }
   else {
   
      barIndex = CURRENT_BAR + 1;
   }
   
   int previousBarIndex = getPreviousBarIndex(barIndex);        
   
   Trend trend = getDynamicPriceZonesTrend();   
   //if( trend == BULLISH_TREND ) {
   
      //NON_LINEAR_KALMAN
      Slope slopeCurr = getNonLinearKalmanSlope(nonLinearKalmanLength, CURRENT_BAR);
      Slope slopePrev = getNonLinearKalmanSlope(nonLinearKalmanLength, previousBarIndex);
      
      if( (latestNonLinearKalmanSlope != BULLISH_SLOPE) // Ignore, already BULLISH_REVERSAL
            && (slopeCurr == BULLISH_SLOPE) && (slopePrev == BULLISH_SLOPE) ) {
         
         latestNonLinearKalmanSlope = BULLISH_SLOPE;
         latestNonLinearKalmanSlopeTime = Time[CURRENT_BAR];         
         return BEARISH_REVERSAL;
      }      
   //}
   //else if( trend == BEARISH_TREND ) {
      else if( (latestNonLinearKalmanSlope != BEARISH_SLOPE) // Ignore, already BEARISH_REVERSAL
             && (slopeCurr == BEARISH_SLOPE) && (slopePrev == BEARISH_SLOPE) ) {
         
         latestNonLinearKalmanSlope = BULLISH_SLOPE;
         latestNonLinearKalmanSlopeTime = Time[CURRENT_BAR];
         return BULLISH_REVERSAL;
      }      
   //}
   
   return CONTINUATION;          
}

Reversal getDynamicPriceZonesAndSrBandsReversal(int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      //SR_BANDS
      double rsBandsUpperLevel   = getSrBandsLevel(SR_BAND_MAIN, barIndex);
      
      if( (rsBandsUpperLevel > zoneLevelPrev)) {
      
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      //SR_BANDS
      double rsBandsLowerLevel   = getSrBandsLevel(SR_BAND_LOWER, barIndex);   
      
      if( (rsBandsLowerLevel < zoneLevelPrev) ) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicMpaAndSomat3Reversal(int length,int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_BULLISH_MAIN, barIndex);
      //DIMPA
      double dynamicMpaUpperLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(length, DYNAMIC_MPA_SIGNAL, barIndex);
      
      if( (somatLevel > dynamicMpaUpperLevel) && (somatLevel > dynamicMpaSignalLevel) ) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_BULLISH_MAIN, barIndex);
      //DIMPA
      double dynamicMpaLowerLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);  
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(length, DYNAMIC_MPA_SIGNAL, barIndex);    
      
      if( (somatLevel < dynamicMpaLowerLevel) && (somatLevel < dynamicMpaSignalLevel) ) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Cross getDynamicMpaAndNonLinearKalmanBandsCross(int dynamicMpaLength, int nonLinearKalmanBandLength, int barIndex) {

   if(latestDynamicMpaAndNonLinearKalmanBandsCrossTime == Time[CURRENT_BAR]) {
      
      return latestDynamicMpaAndNonLinearKalmanBandsCross;
   } 

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DIMPA
      double dynamicSignalLevel = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
            
      //NON_LINEAR_KALMAN_BANDS
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_MIDDLE, barIndex);

      if(nonLinearKalmanBandsLevel > dynamicSignalLevel) {
         
         latestDynamicMpaAndNonLinearKalmanBandsCross = BEARISH_CROSS;
         latestDynamicMpaAndNonLinearKalmanBandsCrossTime = Time[CURRENT_BAR];       
         return BEARISH_CROSS;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DIMPA
      double dynamicSignalLevel = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
            
      //NON_LINEAR_KALMAN_BANDS
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_MIDDLE, barIndex);

      if( nonLinearKalmanBandsLevel < dynamicSignalLevel ) {
         
         latestDynamicMpaAndNonLinearKalmanBandsCross = BULLISH_CROSS;
         latestDynamicMpaAndNonLinearKalmanBandsCrossTime = Time[CURRENT_BAR];         
         return BULLISH_CROSS;
      }      
   }
   
   return latestDynamicMpaAndNonLinearKalmanBandsCross;      
}

/**
 * All crosses must be verified - The pair(SOMAT3 and NON_LINEAR_KALMAN) must have been heading to the opposite direction of the cross before the cross happens.
 */
Cross getSomat3AndNonLinearKalmanCross(int nonLinearKalmanLength,  bool checkPreviousBarClose, bool checkNonLinearKalmanSlope, int barIndex) {

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, CURRENT_BAR);
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(SOMAT3 and NON_LINEAR_KALMAN) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, getPreviousBarIndex(CURRENT_BAR));

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == BULLISH_SLOPE) && (slopePrev == BULLISH_SLOPE) ) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification == BEARISH_SLOPE) )  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         return BULLISH_CROSS;
      }
      else if( ((slopeCurr == BEARISH_SLOPE) && (slopePrev == BEARISH_SLOPE) )// Current and previous slopes are BEARISH_SLOPE
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) )     // Last 2 bar index's should have been BULLISH_SLOPE to validate a BEARISH_CROSS
            {
      
         return BEARISH_CROSS;           
      }     
   }
   else {
   
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the pair(SOMAT3 and NON_LINEAR_KALMAN) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, barIndexForOppositeDirectionVerification);
      
      //Check if current slope changed direction      
      if( (slopeCurr == BULLISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BEARISH_SLOPE) ) 
            {
         
         return BULLISH_CROSS;
      }
      else if( (slopeCurr == BEARISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) ) 
            {
      
         return BEARISH_CROSS;           
      }              
   
   }

   return UNKNOWN_CROSS;      
}
Slope getSomat3AndNonLinearKalmanSlope(int nonLinearKalmanLength, bool checkNonLinearKalmanSlope, int barIndex) {

   double somat3Level  = getSomat3Level(SOMAT3_BULLISH_MAIN, barIndex);
   double nonLinearKalmanLevel  = getNonLinearKalmanLevel(nonLinearKalmanLength, NON_LINEAR_KALMAN_MAIN, barIndex);   

   if(somat3Level < nonLinearKalmanLevel) {

      if(checkNonLinearKalmanSlope) { // More strick if checkNonLinearKalmanSlope==true
         
         return getNonLinearKalmanSlope(nonLinearKalmanLength, barIndex);
      }
      else {
         
         return BULLISH_SLOPE;
      }   
   }
   else if(somat3Level > nonLinearKalmanLevel) {
   
      if(checkNonLinearKalmanSlope) { // More strick if checkNonLinearKalmanSlope==true
         
         return getNonLinearKalmanSlope(nonLinearKalmanLength, barIndex);
      }
      else {
         
         return BEARISH_SLOPE;
      }
   }

   return UNKNOWN_SLOPE;      
}

/**
 * All crosses must be verified - The pair(SOMAT3 and VOLATILITY_BAND) must have been heading to the opposite direction of the cross before the cross happens.
 */
Cross getSomat3AndVolitilityBandsCross(int volitilityBandsLength,  bool checkPreviousBarClose, int barIndex) {

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getSomat3AndVolitilityBandsSlope(volitilityBandsLength, CURRENT_BAR);   
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(SOMAT3 and VOLATILITY_BAND) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3AndVolitilityBandsSlope(volitilityBandsLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope    
      Slope slopePrev = getSomat3AndVolitilityBandsSlope(volitilityBandsLength, getPreviousBarIndex(CURRENT_BAR));      

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == BULLISH_SLOPE) && (slopePrev == BULLISH_SLOPE) ) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification == BEARISH_SLOPE) )  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         return BULLISH_CROSS;
      }
      else if( ((slopeCurr == BEARISH_SLOPE) && (slopePrev == BEARISH_SLOPE) )// Current and previous slopes are BEARISH_SLOPE
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) )     // Last 2 bar index's should have been BULLISH_SLOPE to validate a BEARISH_CROSS
            {
      
         return BEARISH_CROSS;           
      }     
   }
   else {
   
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the pair(SOMAT3 and VOLATILITY_BAND) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3AndVolitilityBandsSlope(volitilityBandsLength, barIndexForOppositeDirectionVerification);
      
      //Check if current slope changed direction      
      if( (slopeCurr == BULLISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BEARISH_SLOPE) ) 
            {
         
         return BULLISH_CROSS;
      }
      else if( (slopeCurr == BEARISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) ) 
            {
      
         return BEARISH_CROSS;           
      }              
   
   }

   return UNKNOWN_CROSS;      
}
Slope getSomat3AndVolitilityBandsSlope(int volitilityBandsLength, int barIndex) {

   double somat3Level  = getSomat3Level(SOMAT3_BULLISH_MAIN, barIndex);
   double volitilityBandsLowerLevel  = getVolitilityBandsLevel(volitilityBandsLength, VOLATILITY_BAND_LOWER, barIndex);   
   double volitilityBandsUpperLevel  = getVolitilityBandsLevel(volitilityBandsLength, VOLATILITY_BAND_UPPER, barIndex);   
                                  
   if(somat3Level > volitilityBandsUpperLevel) {

      return BEARISH_SLOPE;  
   }
   else if(somat3Level < volitilityBandsLowerLevel) { 
      
      return BULLISH_SLOPE;
   }

   return UNKNOWN_SLOPE;      
}

/**
 * All crosses must be verified - The pair(NON_LINEAR_KALMAN and VOLATILITY_BAND) must have been heading to the opposite direction of the cross before the cross happens.
 */
Cross getNonLinearKalmanAndVolitilityBandsCross(int nonLinearKalmanLength, int volitilityBandsLength,  bool checkPreviousBarClose, int barIndex) {

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getNonLinearKalmanAndVolitilityBandsSlope(nonLinearKalmanLength, volitilityBandsLength, checkPreviousBarClose, CURRENT_BAR);   
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(NON_LINEAR_KALMAN and VOLATILITY_BAND) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getNonLinearKalmanAndVolitilityBandsSlope(nonLinearKalmanLength, volitilityBandsLength, checkPreviousBarClose, barIndexForOppositeDirectionVerification);
      
      //Previous slope    
      Slope slopePrev = getNonLinearKalmanAndVolitilityBandsSlope(nonLinearKalmanLength, volitilityBandsLength, checkPreviousBarClose, getPreviousBarIndex(CURRENT_BAR));      

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == BULLISH_SLOPE) && (slopePrev == BULLISH_SLOPE) ) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification == BEARISH_SLOPE) )  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         return BULLISH_CROSS;
      }
      else if( ((slopeCurr == BEARISH_SLOPE) && (slopePrev == BEARISH_SLOPE) )// Current and previous slopes are BEARISH_SLOPE
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) )     // Last 2 bar index's should have been BULLISH_SLOPE to validate a BEARISH_CROSS
            {
      
         return BEARISH_CROSS;           
      }     
   }
   else {
   
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the pair(NON_LINEAR_KALMAN and VOLATILITY_BAND) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getNonLinearKalmanAndVolitilityBandsSlope(nonLinearKalmanLength, volitilityBandsLength, checkPreviousBarClose, barIndexForOppositeDirectionVerification);
      
      //Check if current slope changed direction      
      if( (slopeCurr == BULLISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BEARISH_SLOPE) ) 
            {
         
         return BULLISH_CROSS;
      }
      else if( (slopeCurr == BEARISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) ) 
            {
      
         return BEARISH_CROSS;           
      }              
   
   }

   return UNKNOWN_CROSS;      
}
Slope getNonLinearKalmanAndVolitilityBandsSlope(int nonLinearKalmanLength, int volitilityBandsLength, bool checkNonLinearKalmanSlope, int barIndex) {

   //NON_LINEAR_KALMAN
   double nonLinearKalmanLevel  = getNonLinearKalmanLevel(nonLinearKalmanLength, NON_LINEAR_KALMAN_MAIN, barIndex);   
   
   //VOLATILITY_BAND
   double volitilityBandsLowerLevel  = getVolitilityBandsLevel(volitilityBandsLength, VOLATILITY_BAND_LOWER, barIndex);   
   double volitilityBandsUpperLevel  = getVolitilityBandsLevel(volitilityBandsLength, VOLATILITY_BAND_UPPER, barIndex);   

   if(nonLinearKalmanLevel > volitilityBandsUpperLevel) {

      if(checkNonLinearKalmanSlope) { // More strick if checkNonLinearKalmanSlope==true
         
         return getNonLinearKalmanSlope(nonLinearKalmanLength, barIndex);
      }
      else {
         
         return BEARISH_SLOPE;
      }   
   }
   else if(nonLinearKalmanLevel < volitilityBandsLowerLevel) {
   
      if(checkNonLinearKalmanSlope) { // More strick if checkNonLinearKalmanSlope==true
         
         return getNonLinearKalmanSlope(nonLinearKalmanLength, barIndex);
      }
      else {
         
         return BULLISH_SLOPE;
      }
   }

   return UNKNOWN_SLOPE;    
}

Reversal getDynamicPriceZonesAndSomat3Reversal() {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_BULLISH_MAIN, CURRENT_BAR + 1);
      
      if( (somatLevel > zoneLevelPrev)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_BULLISH_MAIN, CURRENT_BAR + 1);
      
      if( (zoneLevelPrev > somatLevel)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesAndNonLinearKalmanBandsReversal(int nonLinearKalmanBandLength) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //NON_LINEAR_KALMAN_BANDS
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_UPPER, CURRENT_BAR + 1);
      
      if( ( ( latestNonLinearKalmanBandsReversal != BEARISH_REVERSAL) && (nonLinearKalmanBandsLevel > zoneLevelPrev) ) ) {
         
         latestNonLinearKalmanBandsReversalTime = Time[CURRENT_BAR];
         latestNonLinearKalmanBandsReversal = BEARISH_REVERSAL;
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //NON_LINEAR_KALMAN_BANDS
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_LOWER, CURRENT_BAR + 1);
      
      if( ( (latestNonLinearKalmanBandsReversal != BULLISH_REVERSAL) && (zoneLevelPrev > nonLinearKalmanBandsLevel) )) {
         
         latestNonLinearKalmanBandsReversalTime = Time[CURRENT_BAR];
         latestNonLinearKalmanBandsReversal = BULLISH_REVERSAL;
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesAndVolitilityBandsReversal(int volitilityLength, int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //VOLATILITY_BANDS
      double volitilityBandLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);
      
      if( (volitilityBandLevel > zoneLevel)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //VOLATILITY_BANDS
      double volitilityBandLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
      
      if( (zoneLevel > volitilityBandLevel)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesAndSomat3Reversal(int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_BULLISH_MAIN, barIndex);
      
      if( (somatLevel > zoneLevel)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_BULLISH_MAIN, barIndex);
      
      if( (zoneLevel > somatLevel)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesAndHullMaReversal(int length, int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //HULL_MA
      double maLevel = getHullMaLevel(length, LINEAR_MA_BULLISH_VALUE, barIndex);
      
      if( (maLevel > zoneLevel)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //HULL_MA
      double maLevel = getHullMaLevel(length, LINEAR_MA_BULLISH_VALUE, barIndex);
      
      if( (zoneLevel > maLevel)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesAndLinearMaReversal(int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //LINEAR_MA
      double maLevel = getLinearMaLevel(LINEAR_MA_BULLISH_VALUE, barIndex);
      
      if( (maLevel > zoneLevel)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //LINEAR_MA
      double maLevel = getLinearMaLevel(LINEAR_MA_BULLISH_VALUE, barIndex);
      
      if( (zoneLevel > maLevel)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

Reversal getDynamicPriceZonesAndDonchianChannelReversal() {
   
   //DONCHIAN_CHANNEL attr
   int timeFrame           = Period(); 
   int fastChannelPeriod   = 3;
   int fastHighLowShift    = 1;
   bool showMiddle         = false;
   bool useClosePrice      = false;  

   Trend trend = getDynamicPriceZonesTrend();
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR);
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //DONCHIAN_CHANNEL
      double donchianChannelLevelCurr = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, DONCHIAN_CHANNEL_UPPER_LEVEL, CURRENT_BAR);
      double donchianChannelLevelPrev = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, DONCHIAN_CHANNEL_UPPER_LEVEL, CURRENT_BAR + 1);
      
      if( (donchianChannelLevelCurr > zoneLevelCurr) && (donchianChannelLevelPrev > zoneLevelPrev) ) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelCurr  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR);
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //DONCHIAN_CHANNEL
      double donchianChannelLevelCurr = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, DONCHIAN_CHANNEL_LOWER_LEVEL, CURRENT_BAR);
      double donchianChannelLevelPrev = getDonchianChannelLevel(timeFrame, fastChannelPeriod, fastHighLowShift, showMiddle, useClosePrice, DONCHIAN_CHANNEL_LOWER_LEVEL, CURRENT_BAR + 1);

      if( (zoneLevelCurr > donchianChannelLevelCurr) && (zoneLevelPrev > donchianChannelLevelPrev) ) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;
}
/** END REVERSAL DETECTIONS */


string getTime(int barIndex){
   return (string)iTime(Symbol(), CURRENT_TIMEFRAME, barIndex);
}

string getCurrentTime(){
   return (string)iTime(Symbol(), CURRENT_TIMEFRAME, 0);
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

/** START STRATEGIES */
Signal getDynamicPriceZonesAndDynamicMpaAndVolitilityBandsSignal(int length, int barIndex) { 

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      //DYNAMIC_MPA
      double dynamicMpaLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_MAIN, barIndex);
      
      if( (dynamicMpaLevel > zoneLevelPrev) ) {
         
         return SELL_SIGNAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      //DYNAMIC_MPA
      double dynamicMpaLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);   
      
      if( (dynamicMpaLevel < zoneLevelPrev) ) {
         
         return BUY_SIGNAL;
      }      
   }
   
   return NO_SIGNAL;      
}

//T3 Bands
Signal getT3CrossSignal(int barIndex) { 

   Reversal t3OuterBandsReversal = getT3OuterBandsReversal(true);  
   Reversal t3MiddleBandsReversal= getT3MiddleBandsReversal(true);
   if( (t3OuterBandsReversal == BULLISH_REVERSAL) && (t3MiddleBandsReversal == BULLISH_REVERSAL) ) {
   
      return BUY_SIGNAL;
   }
   else if( (t3OuterBandsReversal == BEARISH_REVERSAL) && (t3MiddleBandsReversal == BEARISH_REVERSAL) ) {
   
      return SELL_SIGNAL;
   }
   
   return NO_SIGNAL;
}

//T3 Bands
Signal getT3BandsSquaredAndMainStochCrossSignal(int barIndex) { 

   Reversal t3OuterBandsReversal = getT3OuterBandsReversal(true);  
   Reversal t3MiddleBandsReversal= getT3MiddleBandsReversal(true);
   if( (t3OuterBandsReversal == BULLISH_REVERSAL) && (t3MiddleBandsReversal == BULLISH_REVERSAL) ) {
   
      return BUY_SIGNAL;
   }
   else if( (t3OuterBandsReversal == BEARISH_REVERSAL) && (t3MiddleBandsReversal == BEARISH_REVERSAL) ) {
   
      return SELL_SIGNAL;
   }
   
   return NO_SIGNAL;
}

//T3 Bands
Signal getDynamicOfAveragesLevelCrossSignal(int length, int barIndex) { 

   /*Reversal t3OuterBandsReversal = getDynamicOfAveragesLevel(length, true);  
   Reversal t3MiddleBandsReversal= getT3MiddleBandsReversal(true);
   if( (t3OuterBandsReversal == BULLISH_REVERSAL) && (t3MiddleBandsReversal == BULLISH_REVERSAL) ) {
   
      return BUY_SIGNAL;
   }
   else if( (t3OuterBandsReversal == BEARISH_REVERSAL) && (t3MiddleBandsReversal == BEARISH_REVERSAL) ) {
   
      return SELL_SIGNAL;
   }*/
   
   return NO_SIGNAL;
}
//TODO SE, ML, SR Bands and Dynamic Price Zones

/** END STRATEGIES */

/** START TRENDS */
Trend getDynamicPriceZonesTrend() {

   int midleLevelBuffer = 2;
   
   double priceLevelCurr   = iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);
   double priceLevelPrev  = iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR + 1);
   if( (priceLevelCurr > getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR)) 
         && (priceLevelPrev > getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, (CURRENT_BAR + 1)))) {
         
         return BULLISH_TREND;
   }
   else if( (priceLevelCurr < getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR)) 
         && (priceLevelPrev < getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, (CURRENT_BAR + 1)))) {
         
         return BEARISH_TREND;
   }
   
   return NO_TREND;
}

Trend getDynamicPriceZonesAndMainStochTrend(bool checkPreviousBar) {

   int barIndex = 0;
   if(checkPreviousBar) { 
      
      //MAIN_STOCH
      double stochSignalCurr = getMainStochLevel(MAIN_STOCH_SIGNAL, CURRENT_BAR);      
      
      //DYNAMIC_PRICE_ZONE
      double dynamicPriceZonesMidLevelCurr = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR);
      
      if( stochSignalCurr > dynamicPriceZonesMidLevelCurr) {
            
            return BULLISH_TREND;
      }
      else if( stochSignalCurr < dynamicPriceZonesMidLevelCurr) {
            
            return BEARISH_TREND;
      }      
   }
   else {
      
      int previousBarIndex = getPreviousBarIndex(CURRENT_BAR);
      
      //MAIN_STOCH
      double stochSignalCurr = getMainStochLevel(MAIN_STOCH_SIGNAL, CURRENT_BAR);
      double stochSignalPrev = getMainStochLevel(MAIN_STOCH_SIGNAL, previousBarIndex);
      
      //DYNAMIC_PRICE_ZONE
      double dynamicPriceZonesMidLevelCurr = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR);
      double dynamicPriceZonesMidLevelPrev = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, previousBarIndex);
      
      if( (stochSignalCurr > dynamicPriceZonesMidLevelCurr) && (stochSignalPrev > dynamicPriceZonesMidLevelPrev) ) {
            
            return BULLISH_TREND;
      }
      else if( (stochSignalCurr < dynamicPriceZonesMidLevelCurr) && (stochSignalPrev < dynamicPriceZonesMidLevelPrev) ) {
            
            return BEARISH_TREND;
      }      
   }
   
   return NO_TREND;
}
/** END TRENDS */

void getDynamicPriceZonesAndJurikFilterReversalTest() {

   Reversal rev = getDynamicPriceZonesAndJurikFilterReversal();
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicPriceZonesAndSomat3ReversalTest() {

   Reversal rev = getDynamicPriceZonesAndSomat3Reversal();
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicPriceZonesAndLinearMaReversalTest() {

   Reversal rev = getDynamicPriceZonesAndLinearMaReversal(CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicPriceZonesAndHullMaReversalTest() {

   Reversal rev = getDynamicPriceZonesAndHullMaReversal(18, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicMpaReversalTest() {

   Flatter flatter = getDynamicMpaFlatter(20, false);
   
   if(flatter == BEARISH_FLATTER) {
   
      if(latestDynamicMpaFlatterTime == Time[CURRENT_BAR]) {
         Print("BEARISH FLATTER at: " + getCurrentTime());
      }    
      
   }
   else if(flatter == BULLISH_FLATTER) {
      //Print("BULLISH_FLATTER");
      if(latestDynamicMpaFlatterTime == Time[CURRENT_BAR]) {
         Print("BULLISH FLATTER at: " + getCurrentTime());
      } 
   }     
}

void getDynamicOfAveragesReversalTest() {

   Flatter flatter = getDynamicOfAveragesFlatter(20, false);
   
   if(flatter == BEARISH_FLATTER) {
   
      if(latestDynamicOfAveragesFlatter != BEARISH_FLATTER) {
         
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }          
   }
   else if(flatter == BULLISH_FLATTER) {
      
      if( latestDynamicOfAveragesFlatter != BULLISH_FLATTER ) {      

         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }  
}

void getMainStochReversalTest() {

   Reversal rev = getMainStochReversal(false);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }  
}

void getDimpaAndSomat3ReversalTest() {

   Reversal rev = getDynamicMpaAndSomat3Reversal(20, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicPriceZonesAndVolitilityBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesAndVolitilityBandsReversal(20, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicPriceZonesAndMlsBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesAndMlsBandsReversal(CURRENT_BAR + 1);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestMlsBandsSignalTime != Time[CURRENT_BAR]) {
         
         latestMlsBandsSignal = SELL_SIGNAL;
         latestMlsBandsSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestMlsBandsSignalTime != Time[CURRENT_BAR] ) {      
         
         latestMlsBandsSignal = BUY_SIGNAL;
         latestMlsBandsSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDynamicPriceZonesAndSrBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesAndSrBandsReversal(CURRENT_BAR + 1);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSrBandsSignalTime != Time[CURRENT_BAR]) {
         
         latestSrBandsSignal = SELL_SIGNAL;
         latestSrBandsSignalTime = Time[CURRENT_BAR];
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSrBandsSignalTime != Time[CURRENT_BAR] ) {      
         
         latestSrBandsSignal = BUY_SIGNAL;
         latestSrBandsSignalTime = Time[CURRENT_BAR];
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getDonchianChannelOverlapTest() {

   getDonchianChannelOverlap();
}

void getJurikFilterSlopeTest(){ 

   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   Slope slope = getJurikFilterSlope(CURRENT_BAR + 1);
   
   if( (slope == BULLISH_SLOPE) && (latestJurikSlope != BULLISH_SLOPE) ) {
      
      latestJurikSlope = BULLISH_SLOPE;
      Print("BULLISH SLOPE " + getCurrentTime());
   }
   else if( (slope == BEARISH_SLOPE) && (latestJurikSlope != BEARISH_SLOPE)) {
      
      latestJurikSlope = BEARISH_SLOPE;
      Print("BEARISH SLOPE " + getCurrentTime());
   }
}

void getHullMaSlopeTest(){ 

   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   Slope slope = getHullMaSlope(18, CURRENT_BAR + 1);
   
   if( (slope == BULLISH_SLOPE) && (latestHmaSlope != BULLISH_SLOPE) ) {
      
      latestHmaSlope = BULLISH_SLOPE;
      //Print("BULLISH SLOPE " + getCurrentTime());
   }
   else if( (slope == BEARISH_SLOPE) && (latestHmaSlope != BEARISH_SLOPE)) {
      
      latestHmaSlope = BEARISH_SLOPE;
      //Print("BEARISH SLOPE " + getCurrentTime());
   }
}

void getSrBandsSlopeTest() {
   
   Slope slope = getSrBandsSlope(CURRENT_BAR);
   
   if(slope == BULLISH_SLOPE) {
      Print("SR BANDS is BULLISH");
   }
   else if(slope == BEARISH_SLOPE) {
      Print("SR BANDS is BEARISH");
   }
}

void getDynamicJuricSlopeTest() {
   
   Slope slope = getDynamicJuricSlope(CURRENT_BAR);
   
   if(slope == BULLISH_SLOPE) {
      Print("SR BANDS is BULLISH");
   }
   else if(slope == BEARISH_SLOPE) {
      Print("SR BANDS is BEARISH");
   }
}

void getT3OuterBandsReversalTest() {

   Reversal rev = getT3OuterBandsReversal(true);
   
   if(rev == BEARISH_REVERSAL) {
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
   }   
}

void getT3CrossSignalTest() {

   Signal signal = getT3CrossSignal(true);
   
   if(signal == BUY_SIGNAL) {
         Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
   }
   else if(signal == SELL_SIGNAL) {
      Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
   }   
}

void getJmaBandsLevelCrossReversalTest() {

   Reversal rev = getJmaBandsLevelCrossReversal();
   
   if(rev == BEARISH_REVERSAL) {
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
   }  
}

void getDynamicPriceZonesandJmaBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesandJmaBandsReversal(CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
         Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
   }  
}


void getNonLinearKalmanSlopeTest() {

   Slope slope = getNonLinearKalmanSlope(20, CURRENT_BAR + 1);
    
   if(slope == BULLISH_SLOPE) {
      Print("SR BANDS is BULLISH");
   }
   else if(slope == BEARISH_SLOPE) {
      Print("SR BANDS is BEARISH");
   }  
}

void getDynamicPriceZonesAndMainStochTrendTest() {

   Trend trend = getDynamicPriceZonesAndMainStochTrend(CURRENT_BAR + 1);
   
   if(trend == BULLISH_TREND) {
      Print("In a BULLISH MODE");
   }
   else if(trend == BEARISH_TREND) {
      Print("In a BEARISH MODE");
   }  
}

void getDynamicOfAveragesShortTermTrendTest() {

   Trend trend = getDynamicOfAveragesShortTermTrend(20);
   
   if(trend == BULLISH_SHORT_TERM_TREND) {
      Print("In a BULLISH_SHORT_TERM_TREND MODE at " + getCurrentTime() );
   }
   else if(trend == BEARISH_SHORT_TERM_TREND) {
      Print("In a BEARISH_SHORT_TERM_TREND MODE at " + getCurrentTime() );
   }  
}

//This is concrete - Uses previous close of VolitilityBands. A bit late - needs to be optimised
void getDynamicMpaAndVolitilityBandsReversalTest() {

   if(latestTransitionTime != Time[CURRENT_BAR]) { //Allow only 1 signal per candle
     
      Transition transition = getDynamicMpaAndVolitilityBandsReversal(20, 20, false, true);
      
      if(transition == BULLISH_TO_BEARISH_TRANSITION) {
      
         if(latestTransition != BULLISH_TO_BEARISH_TRANSITION) {
            
            latestTransitionTime = Time[CURRENT_BAR];
            latestTransition = BULLISH_TO_BEARISH_TRANSITION;
            Print("BULLISH_TO_BEARISH_TRANSITION at: " + getCurrentTime());
         }          
      }
      else if(transition == BEARISH_TO_BULLISH_TRANSITION) {
         
         if( latestTransition != BEARISH_TO_BULLISH_TRANSITION ) {      
            
            latestTransitionTime = Time[CURRENT_BAR];
            latestTransition = BEARISH_TO_BULLISH_TRANSITION;
            Print("BEARISH_TO_BULLISH_TRANSITION at: " + getCurrentTime());
         }
      }
      else if(transition == SUDDEN_BULLISH_TO_BEARISH_TRANSITION) {
         if( latestTransition != SUDDEN_BULLISH_TO_BEARISH_TRANSITION ) {      
            
            latestTransitionTime = Time[CURRENT_BAR];
            latestTransition = SUDDEN_BULLISH_TO_BEARISH_TRANSITION;
            Print("SUDDEN_BULLISH_TO_BEARISH_TRANSITION at: " + getCurrentTime());
         }   
      }
      else if(transition == SUDDEN_BEARISH_TO_BULLISH_TRANSITION) {
         if( latestTransition != SUDDEN_BEARISH_TO_BULLISH_TRANSITION ) {      
            
            latestTransitionTime = Time[CURRENT_BAR];
            latestTransition = SUDDEN_BEARISH_TO_BULLISH_TRANSITION;
            Print("SUDDEN_BEARISH_TO_BULLISH_TRANSITION at: " + getCurrentTime());
         }   
      }
   }   
}

void getDynamicPriceZonesAndNonLinearKalmanBandsReversalTest() {

   //Use 15 for getDynamicPriceZonesAndNonLinearKalmanBandsReversal and 20 Dimpa getDynamicMpaAndNonLinearKalmanBandsCross
   Reversal rev = getDynamicPriceZonesAndNonLinearKalmanBandsReversal(15); 
   
   if(rev == BEARISH_REVERSAL) {   
      Print("BEARISH REVERSAL SIGNAL at: " + getCurrentTime());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + getCurrentTime());
   }   
}

void invalidateNonLinearKalmanBandsReversal(int nonLinearKalmanBandLength) {

   if(latestNonLinearKalmanBandsReversal == BEARISH_REVERSAL) {
   
      double dynamicPriceZonesLevel    = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR);
      //If the NON_LINEAR_KALMAN_BANDS_LOWER crosses down the DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL - we can no longer call this a BEARISH_REVERSAL.
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_LOWER, CURRENT_BAR);
      if( dynamicPriceZonesLevel > nonLinearKalmanBandsLevel) {
         
         latestNonLinearKalmanBandsReversal = UNKNOWN;
      } 
   }
   
   if( latestNonLinearKalmanBandsReversal == BULLISH_REVERSAL ) {      
         
      double dynamicPriceZonesLevel    = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR);
      //If the NON_LINEAR_KALMAN_BANDS_UPPER crosses up the DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL - we can no longer call this a BULLISH_REVERSAL.    
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_UPPER, CURRENT_BAR); 
      if( dynamicPriceZonesLevel < nonLinearKalmanBandsLevel) {
         
         latestNonLinearKalmanBandsReversal = UNKNOWN;
      }       
   }   
}

//LATEST TESTS
void getDynamicMpaAndNonLinearKalmanBandsCrossTest() {

   //Use 15 for getDynamicPriceZonesAndNonLinearKalmanBandsReversal and 20 Dimpa getDynamicMpaAndNonLinearKalmanBandsCross
   Cross cross = getDynamicMpaAndNonLinearKalmanBandsCross(20, 20, CURRENT_BAR + 1); 
   
   if(cross == BEARISH_CROSS) {
   
      if(latestDynamicMpaAndNonLinearKalmanBandsCross != BEARISH_CROSS) {
         
         Print("BEARISH CROSS SIGNAL at: " + getCurrentTime());
      }    
      
   }
   else if(cross == BULLISH_CROSS) {
      
      if( latestDynamicMpaAndNonLinearKalmanBandsCross != BULLISH_CROSS ) {      
         
         Print("BULLISH CROSS SIGNAL at: " + getCurrentTime());
      }
   }   
}

void getSomat3AndNonLinearKalmanCrossSlopeTest() {

   Slope slope = getSomat3AndNonLinearKalmanSlope(20, true, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + getCurrentTime());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + getCurrentTime());
   }   
}

void getNonLinearKalmanAndVolitilityBandsSlopeTest() {

   Slope slope = getNonLinearKalmanAndVolitilityBandsSlope(20, 20, true, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + getCurrentTime());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + getCurrentTime());
   }   
}

void getSomat3AndVolitilityBandsSlopeTest() {

   Slope slope = getSomat3AndVolitilityBandsSlope(20, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + getCurrentTime());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + getCurrentTime());
   }   
}