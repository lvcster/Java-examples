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
//|   Notes: Reversal:                                               |
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
#include <PhDLib.mqh>

// General attributes
ENUM_TIMEFRAMES TIMEFRAME  =  NULL; // Current time frame of the chart the EA applied on

// Trade transactions
int slippage            =  5;    // Acceptable price deviation
string buyComment       =  "Buy order triggered by the signal";  // Buy comment
string sellComment      =  "Sell order triggered by the signal"; // Sell comment
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
static string STEP_RSI           =  "-PhD StepRSI";                    
static string OCN_NMC_AND_MA     =  "-PhD OcnMa OffChart Boundries";  
static string IRC_TRIPPLETS      =  "-PhD IRC Tripplets";             
static string IRC_TRIPPLETS_V2   =  "-PhD IRC Tripplets v2";           
static string SOMAT3             =  "-PhD SOMAT3";  
static string DYNAMIC_STEPMA_PDF =  "-PhD DiStepped PdF";  
static string STEPPED_MA         =  "-PhD Stepped MA";             
static string SOMA_LITE          =  "-PhD SOMA Lite";
static string STEPPED_TTA        =  "-PhD Stepped TTA";
static string MR_TRIGGER         =  "-PhD MR-Trigger";                 
static string TREND_SCORE        =  "-PhD TrendScore";                 
static string VELOCITY_STEPS     =  "-PhD Velocity Steps";             
static string SADUKI             =  "-PhD Saduki";                     
static string LEVEL_STOP         =  "-PhD Level Stop";                
static string WCCI               =  "-PhD wCCI";                      
static string TEST               =  "-velocity"; 
static string PERFECT_TREND      =  "-PhD Perfect Trend";              
static string QEPS               =  "-PhD Qeps";                      
static string QEVELO             =  "-PhD QeVelo";                    
static string DYNAMIC_STEEPPED_STOCH   =  "-PhD DySteppedStoch";            
static string DYNAMIC_NOLAG_MA         =  "-PhD DiNoLagMa"; //Multi time frame issues 
static string DYNAMIC_OF_AVERAGES      =  "-PhD DiZOA";
static string DYNAMIC_MPA              =  "-PhD DiMPA";
static string DYNAMIC_EFT              =  "-PhD DiEFT";
static string EFT                      =  "-PhD EFT";
static string DYNAMIC_WPR_OFF_CHART    =  "-PhD DiWPR offChart";
static string DYNAMIC_WPR_ON_CHART     =  "-PhD DiWPR onChart";
static string DYNAMIC_WPR              =  "-PhD DiWpR";
static string DYNAMIC_RSX_OMA          =  "-PhD DiRsXoMA";
static string CYCLE_KROUFR_VERSION     =  "-PhD Cycle";
static string RSI_FILTER               =  "-rsi-filter";

//START BANDS
static string VIDYA_ZONES              =  "-PhD Vidya Zones";
static string KALMAN_BANDS             =  "-PhD Kalma Bands";
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
static string RSIOMA_BANDS             =  "-PhD RsiOMA Bands";
static string QUANTILE_DSS             =  "-PhD Quantile Dss";
//END BANDS

//START FLOATING LEVELS
static string FLOATED_KAUFMAN_RSI =  "-PhD Floated RsX";
static string FLOATED_STEPPED_RSI =  "-PhD Floated Stepped-RSI";
//END FLOATING LEVELS

//START TRIGGERS
static string NON_LINEAR_KALMAN        =  "-PhD NonLinearKalman";
static string LINEAR_MA                =  "-PhD Linear";
static string HULL_MA                  =  "-PhD HMA";
static string JURIK_FILTER             =  "-PhD Jurik filter";
static string NOLAG_MA                 =  "-PhD NonLagMA"; 
static string SUPER_TREND              =  "-PhD SuperTrend";
static string SMOOTHED_DIGITAL_FILTER  =  "-PhD Smoothed Digital Filters";
static string BUZZER                   =  "-PhD Buzzer";
static string BB_STOCH_OF_RSI          =  "-PhD BBnStochVanRSI";
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

//START POLYFIT_BANDS
static int POLYFIT_BAND_MAIN        =  0; //Middle
static int POLYFIT_BAND_FIRST_UPPER =  1;
static int POLYFIT_BAND_FIRST_LOWER =  2;
static int POLYFIT_BAND_SECOND_UPPER=  5;
static int POLYFIT_BAND_SECOND_LOWER=  6;
//END POLYFIT_BANDS

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

//START FLOATED_KAUFMAN_RSI
static int FLOATED_KAUFMAN_RSI_LEVEL_SIGNAL = 0;
static int FLOATED_KAUFMAN_RSI_LEVEL_UPPER  = 3;
static int FLOATED_KAUFMAN_RSI_LEVEL_MIDDLE = 4;
static int FLOATED_KAUFMAN_RSI_LEVEL_LOWER  = 5;
//END FLOATED_KAUFMAN_RSI

//START FLOATED_STEPPED_RSI
static int FLOATED_STEPPED_RSI_FAST    = 0;
static int FLOATED_STEPPED_RSI_SLOW    = 1;
static int FLOATED_STEPPED_RSI_SIGNAL  = 2; 
static int FLOATED_STEPPED_RSI_UPPER   = 5;
static int FLOATED_STEPPED_RSI_MIDDLE  = 6;
static int FLOATED_STEPPED_RSI_LOWER   = 7;
//END FLOATED_STEPPED_RSI

//START SOMAT3
static int SOMAT3_SLOPE    =  0;
static int SOMAT3_MAIN     =  1;
static int SOMAT3_BEARISH  =  2;
//END SOMAT3

//START STEPPED_TTA
static int STEPPED_TTA_MAIN   = 0;
static int STEPPED_TTA_SLOPE  = 3; //EMPTY_VALUE when in BULLISH_SLOPE, !=EMPTY_VALUE when BEARISH_SLOPE
//END STEPPED_TTA

//START HULL_MA
static int HULL_MA_MAIN_VALUE   =  0;
static int HULL_MA_BULLISH_VALUE  =  1;
static int HULL_MA_BEARISH_VALUE  =  2; 
//END HULL_MA

//START BB_STOCH_OF_RSI
static int BB_STOCH_OF_RSI_STOCH    = 0;
static int BB_STOCH_OF_RSI_BB_UPPER = 2;
static int BB_STOCH_OF_RSI_BB_LOWER = 3; 
static int BB_STOCH_OF_RSI_BB_MID   = 4;
//END BB_STOCH_OF_RSI

//START EFT
static int EFT_SIGNAL      = 0;
static int EFT_SLOPE       = 1; //Empty when bullish, not empty when bearish 
static int EFT_SECOND_LINE = 3; //Never empty. Bullish when below EFT_SIGNAL, Bearish when above EFT_SIGNAL
//END EFT 

 //START SE_BANDS
static int SE_BAND_MAIN    = 0;
static int SE_BAND_UPPER   = 1; //Empty when bullish, not empty when bearish 
static int SE_BAND_LOWER   = 2; //Never empty. Bullish when below EFT_SIGNAL, Bearish when above EFT_SIGNAL
//END SE_BANDS 

//START VIDYA_ZONE
static int VIDYA_ZONE_UPPER   = 0;
static int VIDYA_ZONE_MIDDLE  = 1;
static int VIDYA_ZONE_LOWER   = 2;
//START VIDYA_ZONE

//START LINEAR_MA
static int LINEAR_MA_BULLISH_MAIN   =  0;
static int LINEAR_MA_BULLISH_VALUE  =  1;
static int LINEAR_MA_BEARISH_VALUE  =  2; 
//END LINEAR_MA

//START QUANTILE_DSS
static int QUANTILE_DSS_SIGNAL =  0;
static int QUANTILE_DSS_UPPER  =  5;
static int QUANTILE_DSS_LOWER  =  6;
//END QUANTILE_DSS

//START DYNAMIC_MPA
static int DYNAMIC_MPA_UPPER  = 0; //UPPER
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

// START SUPER_TREND
static int SUPER_TREND_MAIN            = 0; 
static int SUPER_TREND_BEARISH_SLOPE   = 1;  //EMPTY_VALUE = BULLISH, !EMPTY_VALUE = BEARISH
// END SUPER_TREND

// START RSIOMA_BANDS
static int RSIOMA_BANDS_SIGNAL  = 0; //SIGNAL
static int RSIOMA_BANDS_UPPER = 1;
static int RSIOMA_BANDS_LOWER = 2;
static int RSIOMA_BANDS_MA    = 3;
static int RSIOMA_BANDS_SLOPE = 4;
static int RSIOMA_BANDS_OVERSOLD_LEVEL    = 20;
static int RSIOMA_BANDS_OVERBOUGHT_LEVEL  = 80;
// END RSIOMA_BANDS

// START DYNAMIC_WPR
static int DYNAMIC_WPR_SIGNAL       = 0;
//static int DYNAMIC_WPR_SECONDLIND = 1;
static int DYNAMIC_WPR_FIRST_LOWER  = 2;
static int DYNAMIC_WPR_FIRST_UPPER  = 3;
static int DYNAMIC_WPR_SECOND_LOWER = 4;
static int DYNAMIC_WPR_SECOND_UPPER = 5;
static int DYNAMIC_WPR_MIDDLE       = 6;
// END DYNAMIC_WPR

// START DYNAMIC_RSX_OMA
static int DYNAMIC_RSX_OMA_SIGNAL = 0;
static int DYNAMIC_RSX_OMA_LOWER  = 1;
static int DYNAMIC_RSX_OMA_UPPER  = 2;
static int DYNAMIC_RSX_OMA_MIDDLE = 3;
// END DYNAMIC_RSX_OMA

// START CYCLE_KROUFR_VERSION
static int CYCLE_KROUFR_VERSION_SIGNAL = 0;
static int CYCLE_KROUFR_VERSION_OVERSOLD_LEVEL  = 10;
static int CYCLE_KROUFR_VERSION_OVERBOUGHT_LEVEL= 90;
// END CYCLE_KROUFR_VERSION

// START DYNAMIC_STEPMA_PDF
static int DYNAMIC_STEPMA_PDF_SIGNAL= 0;
static int DYNAMIC_STEPMA_PDF_SLOPE = 1;//EMPTY_VALUE = BEARISH, EMPTY_VALUE != BULLISH
static int DYNAMIC_STEPMA_PDF_UPPER = 3;
static int DYNAMIC_STEPMA_PDF_LOWER = 4;
// END DYNAMIC_STEPMA_PDF

// START MLS_BANDS
static int MLS_BAND_MAIN      = 0; //UPPER BAND
static int MLS_BAND_LOWER     = 1;
// END MLS_BANDS

//START NON_LINEAR_KALMAN
static int NON_LINEAR_KALMAN_MAIN   = 0; 
static int NON_LINEAR_KALMAN_SLOPE  = 1; //Use to gauge the slope. EMPTY_VALUE = BULLISH, !EMPTY_VALUE = BEARISH
//END NON_LINEAR_KALMAN

//START KALMAN_BANDS
static int KALMAN_BAND_MIDDLE = 0;
static int KALMAN_BAND_UPPER  = 1;
static int KALMAN_BAND_LOWER  = 2;
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
datetime latestEftCrossTime                  = 0;
datetime latestEftSlopeTime                  = 0;
datetime latestTransitionTime                = 0; 
datetime latestSrBandsSignalTime             = 0; 
datetime latestMlsBandsSignalTime            = 0;
datetime latestSomat3ReversalTime            = 0;
datetime latestRsiomaBandsZoneTime           = 0;
datetime latestDynamicMpaCrossTime           = 0;
datetime latestRsiomaBandsCrossTime          = 0;
datetime latestQuantileDssCrossTime          = 0;
datetime latestJmaBandsReversalTime          = 0; 
datetime latestDynamicMpaFlatterTime         = 0;
datetime latestMainStochReversalTime         = 0;
datetime latestDynamicMpaReversalTime        = 0;
datetime latestDynamicJurikReversalTime      = 0;
datetime latestNonLinearKalmanSlopeTime      = 0;
datetime latestT3OuterBandsReversalTime      = 0;
datetime latestT3MiddleBandsReversalTime     = 0;
datetime latestDynamicStepMaPdfCrossTime     = 0;
datetime latestCycleKroufrExtremeZoneTime    = 0;
datetime latestDynamicOfAveragesCrossTime    = 0;
datetime latestStepRSIFloatingReversalTime   = 0;
datetime latestRsiomaBandsZoneReversalTime   = 0;
datetime latestDynamicOfAveragesFlatterTime  = 0;
datetime latestDynamicRsxOmaExtremeZoneTime  = 0;
datetime latestDynamicStepMaPdfReversalTime  = 0;
datetime latestDynamicOfAveragesReversalTime = 0;
datetime latestStepRSIFloatingExtremeZoneTime= 0;
datetime latestNonLinearKalmanBandsReversalTime    = 0;
datetime latestDynamicOfAveragesCrossSignalTime    = 0;
datetime latestSomat3AndNonLinearKalmanCrossTime   = 0;
datetime latestCycleKroufrExtremeZoneReversalTime  = 0;
datetime latestDynamicOfAveragesShortTermTrendTime = 0;
datetime latestDynamicRsxOmaExtremeZoneReversalTime= 0;
datetime latestDynamicMpaAndVolitilityBandsCrossTime     = 0;
datetime latestDynamicPriceZonesAndSomat3ReversalTime    = 0;
datetime latestStepRSIFloatingExtremeZoneReversalTime     = 0;
datetime latestDynamicPriceZonesandJmaBandsReversalTime  = 0;
datetime latestDynamicMpaAndNonLinearKalmanBandsCrossTime= 0;
datetime latestDynamicMpaSignalLevelAndVolitilityBandsCrossTime = 0;

//Invalidation time
datetime invalidateDynamicRsxOmaExtremeZoneTime = 0;

//Tests
datetime dynamicMpaAndVolitilityBandsCombinedCrossTime=0;

//Reversal
Reversal latestSomat3Reversal                = UNKNOWN;
Reversal latestJmaBandsReversal              = UNKNOWN;
Reversal latestMainStochReversal             = UNKNOWN;
Reversal latestDynamicMpaReversal            = UNKNOWN;
Reversal latestT3OuterBandsReversal          = UNKNOWN;
Reversal latestT3MiddleBandsReversal         = UNKNOWN;
Reversal latestStepRSIFloatingReversal       = UNKNOWN;
Reversal latestRsiomaBandsZoneReversal       = UNKNOWN;
Reversal latestDynamicStepMaPdfReversal      = UNKNOWN;
Reversal latestDynamicOfAveragesReversal     = UNKNOWN;
Reversal latestNonLinearKalmanBandsReversal  = UNKNOWN;
Reversal latestCycleKroufrExtremeZoneReversal= UNKNOWN;
Reversal latestDynamicRsxOmaExtremeZoneReversal    = UNKNOWN;
Reversal latestStepRSIFloatingExtremeZoneReversal  = UNKNOWN;
Reversal latestDynamicPriceZonesAndSomat3Reversal  = UNKNOWN;
Reversal latestDynamicPriceZonesandJmaBandsReversal= UNKNOWN;

//Zones
Zones latestRsiomaBandsZone            = UNKNOWN_ZONE;
Zones latestCycleKroufrExtremeZone     = UNKNOWN_ZONE;
Zones latestDynamicRsxOmaExtremeZone   = UNKNOWN_ZONE;
Zones latestStepRSIFloatingExtremeZone = UNKNOWN_ZONE;

Slope latestEftSlope = UNKNOWN_SLOPE;

Flatter latestDynamicMpaFlatter = NO_FLATTER;
Flatter latestDynamicOfAveragesFlatter = NO_FLATTER;

//Trends
Trend latestDynamicOfAveragesShortTermTrend  = NO_TREND;

//Crosses
Cross latestEftCross                = UNKNOWN_CROSS; 
Cross latestDynamicMpaCross         = UNKNOWN_CROSS; 
Cross latestQuantileDssCross        = UNKNOWN_CROSS;
Cross latestRsiomaBandsCross        = UNKNOWN_CROSS;
Cross latestDynamicStepMaPdfCross   = UNKNOWN_CROSS;
Cross latestDynamicOfAveragesCross  = UNKNOWN_CROSS;
Cross latestSomat3AndNonLinearKalmanCross       = UNKNOWN_CROSS;
Cross dynamicMpaAndVolitilityBandsCombinedCross = UNKNOWN_CROSS;
Cross latestDynamicMpaAndVolitilityBandsCross   = UNKNOWN_CROSS;
Cross latestDynamicMpaAndNonLinearKalmanBandsCross = UNKNOWN_CROSS;
Cross latestDynamicMpaSignalLevelAndVolitilityBandsCross = UNKNOWN_CROSS;
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
   //getDynamicPriceZonesAndNonLinearKalmanBandsReversalTest();

   //getDynamicMpaAndNonLinearKalmanBandsCrossTest();
   
   //getNonLinearKalmanAndVolitilityBandsSlopeTest();
   //getSomat3AndVolitilityBandsSlopeTest();
   //getDynamicMpaAndNonLinearKalmanBandsSlopeTest();
   //getDynamicMpaAndSlopeTest();
   //getDynamicMpaCrossTest();
   //getDynamicMpaSignalLevelAndVolitilityBandsCrossTest();
   //getRsiomaBandsSlopeTest();
   //getRsiomaBandsCrossTest();
   //getQuantileDssSlopeTest();
   //getQuantileDssCrosstTest();
   //getDynamicMpaAndVolitilityBandsSlopeTest();
   //getDynamicMpaAndVolitilityBandsCrossTest();
   //getDynamicMpaAndVolitilityBandsReversalTest();   
   //getDynamicMpaSignalLevelAndVolitilityBandsSlopeTest();
   //getDynamicMpaAndVolitilityBandsCombinedCrossTest();

   //getDynamicPriceZonesandJmaBandsReversalTest();
   //getJmaBandsLevelCrossReversalTest();  
   //getDynamicOfAveragesReversalTest();
   //getSomat3AndNonLinearKalmanSlopeTest();
   //getSomat3AndNonLinearKalmanCrossTest();
   //getEftSlopeTest();
   //getEftCrossTest();

   
   
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
   
   //STRATEGY CONTEDERS
   getRsiomaBandsZoneReversalTest();
   //getDynamicStepMaPdfCrossTest();
   //getDynamicStepMaPdfSlopeTest();

   //getSomat3SlopeTest();
   //getDynamicRsxOmaExtremeZoneReversalTest();
   //getCycleKroufrExtremeZoneReversalTest();

   //getRsiomaBandsZonesTest();
   //getCycleKroufRLevelSlopeTest();
   //getCycleKroufRLevelExtremeZoneTest();
   
   
   //getStepRSIFloatingLevelTest();
   //getStepRSIFloatingExtremeZoneTest();
   //getStepRSIFloatingSlopeTest();
   //getStepRSIFloatingSlopeReversalTest();
   //getDynamicRsxOmaLevelSlopeTest();
   //getDynamicRsxOmaExtremeZoneTest();


   //getSteppedTtaSlopeTest();   
   //getVidyaZonesLevelTest();
   //getSuperTrendSlopeTest();
   //getSomat3AndKalmanBandsSlopeTest();
   //getSomat3AndSeBandsSlopeTest();   
   //getSomat3AndPolyfitBandsSlopeTest();
   //getBBnStochOfRsiSlopeTest();

   //getDynamicPriceZonesAndSomat3ReversalTest();   
   invalidateDynamicPriceZonesLinkedSignals(20);
   return;

      
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
   
   return OrderSend(Symbol(), lOrderType, lVolume, price, slippage, initialStopLevel, takeProfitPrice, orderComment, lMagicNumber, ORDER_EXPIRATION_TIME, arrowColor);
}

void processTradeManagement(int lBreakEvenPoints, int lTrailingStopPoints, int lTargetPointsBeforeTrailingStop, int pastCandleIndex) {

   //TODO: MANAGE TRADES
   return;

   if ( orderExists(Symbol()) == false ) {
         
      // No open orders for this Symbol            
      if (reEnterOnNextSetup) { // If this is false - No follow up trades will be open on the same trend after both auto and manual TP/SL. 
                                // Setup attributes will only reset on the next setup.

         // If trades for this Symbol() has been auto TPd, SLd. This Symbol() won't be in OrdersTotal().
         // Therefore clearing attributes is required to make way for the next setup in the same trend. 
         resetTradeSetupAttributes();
      } 
      
      if (debug) {
         Print("Open orders: " + (string) OrdersTotal() + ". None for " + Symbol()); 
         Print("Exit processTradeManagement."); 
      }
      
      //No open orders for this Symbol, thefore nothing to modify - return 
      return;
   }

   for (int count = 0; count < OrdersTotal(); count++) {
      
      if (OrderSelect(count, SELECT_BY_POS, MODE_TRADES)) {
      
         // Only open orders for current symbol
         if ( OrderCloseTime() == 0 && OrderSymbol() == Symbol()) { 
         
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

   //return getDynamicMpaAndVolitilityBandsCombinedCrossTest();
   //return StrategyTester();
   

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

   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);                                          

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
                                          
   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
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
                                          
   double priceClose =  iClose(Symbol(), Period(), barIndex);                                          
   
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
   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, barIndex);                                          
   

   return (upValue != EMPTY_VALUE) && (upValue > 0 && priceClose > upValue); 
}
/** END SuperTrend1 Buy */

/** START SuperTrend1 sell*/
bool isSuperTrend1Sell(int barIndex) {

   double downValue = NormalizeDouble(iCustom(Symbol(), Period(), "--SuperTrend1", 1, barIndex), Digits);
                                          
   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, barIndex);                                          
   
   return (downValue != EMPTY_VALUE) && (downValue > 0 && downValue > priceClose); 
}
/** END SuperTrend1 sell */

/** START PhD SuperTrend Buy*/
bool isPhDSuperTrendBuy(int barIndex) {

   int nbr_periods = 10;
   double multiplier = 2.0;
   double upValue  = NormalizeDouble(iCustom(Symbol(), Period(), "--PhD SuperTrend", nbr_periods, multiplier, 0, barIndex), Digits);
   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, barIndex);    
   
   return (upValue != EMPTY_VALUE) && (upValue > 0 && priceClose > upValue); 
}
/** END PhD SuperTrend Buy */

/** START PhD SuperTrend v2.0 sell*/
bool isPhDSuperTrendV2Sell(int barIndex) {

   int nbr_periods = 10;
   double multiplier = 2.0;
   double downValue  = NormalizeDouble(iCustom(Symbol(), Period(), "--PhD SuperTrend v2.0", nbr_periods, multiplier, 1, barIndex), Digits);
   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, barIndex);                                          
   
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
                                          
   double priceClose =  iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
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
                                          
   double priceClose  =  iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);                                          
                            
                                         
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
                                          
   double priceClose  =  iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
   return (priceClose > gann5213); 
}

bool isGannHiLoActivatorSell(int _period, int barIndex) {
  
   int lb = 52;
   int lb2 = 13;   
   
   double gann5213 = NormalizeDouble(iCustom(Symbol(), Period(), "Gann Hi-lo Activator SSL", _period, 0, barIndex), Digits);
                                          
   double priceClose  =  iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);                                          
   
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
double getJurikFilterLevelStopLossLevel(int length, int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR; //Use current bar as the previous will definately be in the direction of the trade for this indicator. 
   double jurikFilterLevel = getJurikFilterLevel(length, buffer, barIndex);
  
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

/** Start - SUPER_TREND Stop Loss */
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
/** Start - SUPER_TREND Stop Loss */

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
   
   double closePrice = NormalizeDouble( iOpen(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR + 1), Digits );
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
         if( OrderCloseTime() == 0 && OrderSymbol() == Symbol()) { 
           
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

/*Start: SUPER_TREND Setup */ 
int getSuperTrendSetup(bool _validatePreviousbar) {

   ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;
   int     length        = 10;  
   double  mutliplier    = 3;  
   
   if( _validatePreviousbar == false) {      

      double upTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, timeFrame, length, mutliplier, 0, CURRENT_BAR), Digits);
      double downTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, timeFrame, length, mutliplier, 1, CURRENT_BAR), Digits);

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
      double upTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, timeFrame, length, mutliplier, 0, CURRENT_BAR), Digits);
      double downTrendCurrent = NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, timeFrame, length, mutliplier, 1, CURRENT_BAR), Digits);
      
      double upTrendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, timeFrame, length, mutliplier, 0, CURRENT_BAR + 1), Digits);
      double downTrendPrev = NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, timeFrame, length, mutliplier, 1, CURRENT_BAR + 1), Digits);    
            
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
Zones getEftSentiments(int length, double overBoughtLevel, double overSoldLevel) {
                              
   double eftLevel = getEftLevel(length, 0, 0);
   
   if (eftLevel > overBoughtLevel) {
      
      Print("BULLISH_EXTREME_ZONE");
      return BULLISH_EXTREME_ZONE;
   }
   else if(eftLevel < overSoldLevel) {
   
      Print("BEARISH_EXTREME_ZONE");
      return BEARISH_EXTREME_ZONE;
   }
   else {
   
      return NORMAL_ZONE;
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
   
      return BEARISH_EXTREME_ZONE;
   }
   else if(value > 90) {
      
      return BULLISH_EXTREME_ZONE;
   }
   else {
   
      return NORMAL_ZONE;
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
   
   invalidateStepRSIFloatingExtremeZone(getPreviousBarIndex(CURRENT_BAR));
   
   //invalidateDynamicPriceZonesAndSomat3Reversal();
   
   //RELOOK
   /*if(latestDynamicOfAveragesReversal == UNKNOWN) {
   
      Print("UNKNOWN at " + convertCurrentTimeToString() );
   }
   
   if( (latestDynamicOfAveragesReversal == BEARISH_REVERSAL) && (getDynamicOfAveragesShortTermTrend(length) != BULLISH_SHORT_TERM_TREND) ) {
      
      int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
      int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);
      
      if(latestDynamicOfAveragesReversalBarShift > 2) {
         
         Print("BEARS DEVIATED at " + convertCurrentTimeToString() );
      }
   } 
   
   if( (latestDynamicOfAveragesReversal == BULLISH_REVERSAL) && (getDynamicOfAveragesShortTermTrend(length) != BULLISH_SHORT_TERM_TREND) ) {
      
      int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
      int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);
      
      if(latestDynamicOfAveragesReversalBarShift > 2) {
         
         Print("BULLS DEVIATED at " + convertCurrentTimeToString() );
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
   double somat3Curr = getSomat3Level(SOMAT3_MAIN, CURRENT_BAR); 
   double somat3Prev = getSomat3Level(SOMAT3_MAIN, CURRENT_BAR + 1);      
      
}
void invalidateDynamicPriceZonesAndSomat3Reversal() {

   int previousBarIndex = getPreviousBarIndex(CURRENT_BAR);
   Slope slopePrev = getSomat3Slope(getPreviousBarIndex( previousBarIndex) );

   if(latestDynamicPriceZonesAndSomat3Reversal == BEARISH_REVERSAL) {
   
      int latestDynamicPriceZonesAndSomat3ReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicPriceZonesAndSomat3ReversalTime);
      if(latestDynamicPriceZonesAndSomat3ReversalBarShift > 0) {
         
         latestSignal = NO_SIGNAL;
         latestDynamicPriceZonesAndSomat3Reversal = UNKNOWN;
         //Print("BEARISH_REVERSAL Signal invalidated at " + convertCurrentTimeToString());
      }
      return;
      
      double dynamicPriceZonesLevel    = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR);
      //If the SOMAT3_MAIN crosses down the DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL - we can no longer call this a BEARISH_REVERSAL.
      double somat3Level = getSomat3Level(SOMAT3_MAIN, CURRENT_BAR);
      if( dynamicPriceZonesLevel > somat3Level) {

         latestSignal = NO_SIGNAL;
         latestDynamicPriceZonesAndSomat3Reversal = UNKNOWN;
      } 
      
      if( (slopePrev != BEARISH_SLOPE)){
         
         Print("We have registered a fake BULLISH_REVERSAL signal @ " + convertCurrentTimeToString() + " " + (string)latestDynamicPriceZonesAndSomat3Reversal);
      }      
   }
   
   else if( latestDynamicPriceZonesAndSomat3Reversal == BULLISH_REVERSAL ) {     
   
      int latestDynamicPriceZonesAndSomat3ReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicPriceZonesAndSomat3ReversalTime);
      if(latestDynamicPriceZonesAndSomat3ReversalBarShift > 0) {
         
         latestSignal = NO_SIGNAL;
         latestDynamicPriceZonesAndSomat3Reversal = UNKNOWN;
         //Print("BULLISH_REVERSAL Signal invalidated at " + convertCurrentTimeToString());
      }
      return;    
         
      double dynamicPriceZonesLevel    = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL, CURRENT_BAR);
      //If the SOMAT3_MAIN crosses up the DYNAMIC_PRICE_ZONE_MIDDLE_LEVEL - we can no longer call this a BULLISH_REVERSAL.    
      double somat3Level = getSomat3Level(SOMAT3_MAIN, CURRENT_BAR);
      if( dynamicPriceZonesLevel < somat3Level) {

         latestSignal = NO_SIGNAL;
         latestDynamicPriceZonesAndSomat3Reversal = UNKNOWN;
      }     
      
      if( (slopePrev != BULLISH_SLOPE) ){

         Print("We have registered a fake BEARISH_REVERSAL signal @ " + convertCurrentTimeToString() + " " + (string)latestDynamicPriceZonesAndSomat3Reversal);
      }            
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

void invalidateDynamicRsxOmaExtremeZoneOnReversal() {

   //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
   if( (latestDynamicRsxOmaExtremeZoneReversal == BEARISH_REVERSAL) || (latestDynamicRsxOmaExtremeZoneReversal == BULLISH_REVERSAL)) {
      
      //If there was any signal given, //Invalidate the extreme zones after giving the signal as the signal must be back inside the bands
      invalidateDynamicRsxOmaExtremeZoneTime = getCurrentTime();
      latestDynamicRsxOmaExtremeZone = UNKNOWN_ZONE;
   }   
}

void invalidateCycleKroufrExtremeZoneOnReversal() {

   //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
   if( (latestCycleKroufrExtremeZoneReversal == BEARISH_REVERSAL) || (latestCycleKroufrExtremeZoneReversal == BULLISH_REVERSAL)) {
      
      //If there was any signal given, //Invalidate the extreme zones after giving the signal as the signal must be back inside the bands
      latestCycleKroufrExtremeZoneTime = getCurrentTime();
      latestCycleKroufrExtremeZone = UNKNOWN_ZONE;
   }   
}

void invalidateStepRSIFloatingExtremeZone(int barIndex) {

   Slope slope = getStepRSIFloatingSlope(barIndex);

   if(latestStepRSIFloatingExtremeZone == BULLISH_EXTREME_ZONE) {
   
      
      if( slope == BEARISH_SLOPE) {
         
         //Print("BULLISH_EXTREME_ZONE invalidated @ " + getCurrentTime());
         latestSignal = NO_SIGNAL;
         latestStepRSIFloatingExtremeZone       = UNKNOWN_ZONE;
         latestStepRSIFloatingExtremeZoneTime   = 0;
      } 
   }
   
   if( latestStepRSIFloatingExtremeZone == BEARISH_EXTREME_ZONE ) {      
             
      if( slope == BULLISH_SLOPE) {
          
         //Print("BEARISH_EXTREME_ZONE invalidated @ " + getCurrentTime());
         latestSignal = NO_SIGNAL;
         latestStepRSIFloatingExtremeZone       = UNKNOWN_ZONE;
         latestStepRSIFloatingExtremeZoneTime   = 0;
      }        
   }   
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

   if(checkedBar == getCurrentTime()) {
      
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
         
         checkedBar = getCurrentTime();
         Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
         return BEARISH_REVERSAL;
      }        
   }
   else if( (getNoLagMaLevel(downTrendBuffer, CURRENT_BAR + 1) != EMPTY_VALUE) 
         && (getNoLagMaLevel(downTrendBuffer, CURRENT_BAR + 2) != EMPTY_VALUE)) { //Prev 2 was up - atleast minor trend in place, enough to search for reversal
   
      //currently bearish, look out for bullish reversal
      if( getNoLagMaLevel(downTrendBuffer, CURRENT_BAR) == getNoLagMaLevel(downTrendBuffer, CURRENT_BAR + 1)) { //It will start by being equal and change as price moves away, thus confirming the reversal
         
         checkedBar = getCurrentTime();
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
            Print("BEARISH REVERSAL on " + convertCurrentTimeToString());
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
            Print("BULLISH REVERSAL on " + convertCurrentTimeToString());
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
            Print("BEARISH REVERSAL on " + convertCurrentTimeToString());
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
            Print("BULLISH REVERSAL on " + convertCurrentTimeToString());
         }
      }
      
   }   
   
   return CONTINUATION;
}
/** End - DONCHIAN_CHANNEL Reversal Detection*/

/** One touch of the previous bar(CURRENT_BAR + 1) should be enough to warrant a reversal */
//TODO
Reversal getDynamicPriceZonesAndHurstChannelReversal(int length) { //Hurst 4, 8, 5, 0, 1

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBullishValuePrev  = getJurikFilterLevel(length, JURIK_FILTER_BULLISH_VALUE, CURRENT_BAR + 1);
      
      if( (jurikFilterBullishValuePrev > zoneLevelPrev)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBearishValuePrev  = getJurikFilterLevel(length, JURIK_FILTER_BEARISH_VALUE, CURRENT_BAR + 1);
      
      if( (zoneLevelPrev > jurikFilterBearishValuePrev)) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}


/** Start - DONCHIAN_CHANNEL Reversal Detection*/
Reversal getDonchianChannelReversal(bool useClosePrice) {

   if(checkedBar == getCurrentTime()) {
      
      return CONTINUATION;
   } 
   
   int upperBuffer   = 0;
   int lowerBuffer   = 1; 
   
   
   
   /*if( getDonchianChannelLevel(useClosePrice, upperBuffer, CURRENT_BAR) == getDonchianChannelLevel(useClosePrice, upperBuffer, CURRENT_BAR + 1) ) { 
      
      checkedBar = getCurrentTime();
      Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
      return BEARISH_REVERSAL;       
   }
   if( getDonchianChannelLevel(useClosePrice, lowerBuffer, CURRENT_BAR) == getDonchianChannelLevel(useClosePrice, lowerBuffer, CURRENT_BAR + 1) ) { 
   
      checkedBar = getCurrentTime();
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
   if(latestDynamicJurikReversalTime == getCurrentTime()) {      
      
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
         
         latestDynamicJurikReversalTime = getCurrentTime();
         return BEARISH_REVERSAL;       
      }
   }   
   else if( trend == BEARISH_TREND ) {   
      
      if( getDynamicJuricLevel(DYNAMIC_JURIK_SECOND_LOWER_VALUE, previousBarIndex) == getDynamicJuricLevel(DYNAMIC_JURIK_SECOND_LOWER_VALUE, barIndex) ) { 
      
         latestDynamicJurikReversalTime = getCurrentTime();
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
   if(latestMainStochReversalTime == getCurrentTime()) {      
      
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
         latestMainStochReversalTime = getCurrentTime();
         return BEARISH_REVERSAL;       
      }
   }
   else if( trend == BEARISH_TREND ) {
      
      if( getMainStochLevel(MAIN_STOCH_SECOND_LOWER_VALUE, previousBarIndex ) == getMainStochLevel(MAIN_STOCH_SECOND_LOWER_VALUE, barIndex) ) { 
      
         latestMainStochReversal = BULLISH_REVERSAL;
         latestMainStochReversalTime = getCurrentTime();
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

   if(latestDynamicMpaFlatterTime == getCurrentTime()) {
      
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

   if( (getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, previousBarIndex) == getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, barIndex)) ) { 
      
      latestDynamicMpaFlatter = BEARISH_FLATTER;      
      latestDynamicMpaFlatterTime = getCurrentTime();
      return BEARISH_FLATTER;       
   }
   else if( (getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, previousBarIndex) == getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex)) ) {
      
      latestDynamicMpaFlatter = BULLISH_FLATTER;
      latestDynamicMpaFlatterTime = getCurrentTime();
      return BULLISH_FLATTER;     
   }

   return latestDynamicMpaFlatter;
}
/** End - DYNAMIC_MPA Flat Detection*/

/** 
 *Start - DYNAMIC_OF_AVERAGES Flat Detection - The way this is checked assumes Bullish and Bearish reversal cannot at the same time.
 */
Flatter getDynamicOfAveragesFlatter(int length, bool checkCurrentBar) {

   if(latestDynamicOfAveragesFlatterTime == getCurrentTime()) {
      
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
      latestDynamicOfAveragesFlatterTime = getCurrentTime();
      return BULLISH_FLATTER;     
   }   
   else if( ( dynamicOfAveragesUpperLevelPrev == dynamicOfAveragesUpperLevelCurr) 
         //&& ( (dynamicOfAveragesSignalLevelCurr < dynamicOfAveragesUpperLevelCurr) )
         
         //This is to make sure DynamicOfAverages is currently BULLISH, as it should be before we can expect any BEARISH_REVERSAL reversals 
         //&& (getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR ) > getDynamicOfAveragesLevel(length, DYNAMIC_OF_AVAERAGES_MIDDLE, CURRENT_BAR ) )
         ) { 
      Print("Test");
      latestDynamicOfAveragesFlatter     = BEARISH_FLATTER;
      latestDynamicOfAveragesFlatterTime = getCurrentTime();
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
   

   if(latestDynamicOfAveragesCrossSignalTime == getCurrentTime()) {
      
      return latestDynamicOfAveragesCrossSignal;
   } 

   Cross cross = getDynamicOfAveragesCross(fastDynamicOfAveragesLength, slowDynamicOfAveragesLength, checkPreviousBar);

   if(checkFlatOnFastDynamicOfAverages) { //DYNAMIC_OF_AVERAGES flat must be in place
      
      Flatter flatter = getDynamicOfAveragesFlatter(fastDynamicOfAveragesLength, false); //check previos 2 bars - TODO check if current is check(as it must by default)
      if(flatter == BEARISH_FLATTER) {
      
         if(cross == BULLISH_CROSS) {

            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = getCurrentTime();
         }                   
      }
      else if(flatter == BULLISH_FLATTER) {
      
         cross = getDynamicOfAveragesCross(fastDynamicOfAveragesLength, slowDynamicOfAveragesLength, checkPreviousBar);
         if(cross == BEARISH_CROSS) {
            
            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = getCurrentTime();
         } 
      }       
        
   }
   else { //DYNAMIC_OF_AVERAGES flat can be ignored
   
         if(cross == BULLISH_CROSS) {

            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = getCurrentTime();
         } 
         else if(cross == BEARISH_CROSS) {
            
            latestDynamicOfAveragesCrossSignal = SELL_SIGNAL;
            latestDynamicOfAveragesCrossSignalTime = getCurrentTime();
         }

   }

   return NO_SIGNAL;
}
/** End - DYNAMIC_MPA Reversal Detection*/

/** 
 *Start - DYNAMIC_OF_AVERAGES Cross Detection
 */
Cross getDynamicOfAveragesCross(int fastDynamicOfAveragesLength, int slowDynamicOfAveragesLength, bool checkPreviousBar) {

   if(latestDynamicOfAveragesCrossTime == getCurrentTime()) {
      
      return latestDynamicOfAveragesCross;
   } 

   if(checkPreviousBar) {
   
      double fastDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(fastDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      double slowDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(slowDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      
      double fastDynamicOfAveragesMiddleLevelPrev = getDynamicOfAveragesLevel(fastDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, getPreviousBarIndex(CURRENT_BAR) );
      double slowDynamicOfAveragesMiddleLevelPrev = getDynamicOfAveragesLevel(slowDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, getPreviousBarIndex(CURRENT_BAR) );
      
      if( (slowDynamicOfAveragesMiddleLevelCurr < fastDynamicOfAveragesMiddleLevelCurr) && (slowDynamicOfAveragesMiddleLevelPrev < fastDynamicOfAveragesMiddleLevelPrev) ) {      
      
         latestDynamicOfAveragesCross = BEARISH_CROSS;
         latestDynamicOfAveragesCrossTime = getCurrentTime();
         return BEARISH_CROSS;
      }            
   }
   else {
      
      double fastDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(fastDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      double slowDynamicOfAveragesMiddleLevelCurr = getDynamicOfAveragesLevel(slowDynamicOfAveragesLength, DYNAMIC_OF_AVAERAGES_SIGNAL, CURRENT_BAR );
      
      if( slowDynamicOfAveragesMiddleLevelCurr < fastDynamicOfAveragesMiddleLevelCurr ) {      
      
         latestDynamicOfAveragesCross = BULLISH_CROSS;
         latestDynamicOfAveragesCrossTime = getCurrentTime();
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
      latestJmaBandsReversalTime = getCurrentTime();
      return BULLISH_REVERSAL;          
   }
   else if( (pastTwoJmaBandsLevelSlower < pastTwoJmaBandsLevelFaster) //It was Bullish
         && (pastJmaBandsLevelFaster < pastJmaBandsLevelSlower)  //It turned Bearish on previous
         && (currJmaBandsLevelFaster < currJmaBandsLevelSlower) ) { //It is currently Bearish
         
      latestJmaBandsReversal     = BEARISH_REVERSAL;   
      latestJmaBandsReversalTime = getCurrentTime();
      return BEARISH_REVERSAL;          
   }
  
  
   return CONTINUATION;
}
/** End - JMA_BANDS Reversal Detection*/


/** Start - QUANTILE_BANDS Reversal Detection*/
Reversal getQuantileBandsReversal() {

   if(checkedBar == getCurrentTime()) {
      
      return CONTINUATION;
   } 
   
   int upperBuffer   = 0;
   int lowerBuffer   = 3; 
   
   if( getQuantileBandsLevel(upperBuffer, CURRENT_BAR) == getQuantileBandsLevel(upperBuffer, CURRENT_BAR + 1) ) { 
      
      checkedBar = getCurrentTime();
      Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
      return BEARISH_REVERSAL;       
   }
   if( getQuantileBandsLevel(lowerBuffer, CURRENT_BAR) == getQuantileBandsLevel(lowerBuffer, CURRENT_BAR + 1) ) { 
   
      checkedBar = getCurrentTime();
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
   
    double hmaMainValuePrev = getHullMaLevel(length, HULL_MA_MAIN_VALUE, CURRENT_BAR + 1);
    double hmaMainValuePrevPrev = getHullMaLevel(length, HULL_MA_MAIN_VALUE, CURRENT_BAR + 1);
   
   double hmaBullishValueCurr = getHullMaLevel(length, HULL_MA_BULLISH_VALUE, CURRENT_BAR);
   double hmaBullishValuePrev = getHullMaLevel(length, HULL_MA_BULLISH_VALUE, CURRENT_BAR + 1);
      
   double hmaBearishValueCurr = getHullMaLevel(length, HULL_MA_BEARISH_VALUE, CURRENT_BAR);
   double hmaBearishValuePrev = getHullMaLevel(length, HULL_MA_BEARISH_VALUE, CURRENT_BAR + 1);
   
   if( latestTransitionTime != getCurrentTime() ) {
      
      if(hmaMainValuePrev == hmaMainValuePrevPrev) {
         
         Print("Flat @ " + convertCurrentTimeToString() );
         
         latestTransitionTime = getCurrentTime();
         if( (hmaBullishValuePrev != EMPTY_VALUE) && (hmaBearishValuePrev == EMPTY_VALUE)) {
            
            Print("Slope was Bullish @ " + convertTimeToString(CURRENT_BAR + 1) + " and is now... ");
            if( (hmaBullishValueCurr != EMPTY_VALUE) && (hmaBearishValueCurr == EMPTY_VALUE)) { 
            
               Print("...Bullish @ " + convertCurrentTimeToString() ); 
            } 
            else if( (hmaBearishValueCurr != EMPTY_VALUE) && (hmaBullishValueCurr != EMPTY_VALUE)) { 
               
               Print("...Bearish @ " + convertCurrentTimeToString() );
            }            
         }
         else if( (hmaBearishValuePrev != EMPTY_VALUE) && (hmaBullishValuePrev == EMPTY_VALUE)) {
            
            Print("Slope was Bearish @ " + convertTimeToString(CURRENT_BAR + 1) + " and is now... ");
            if( (hmaBullishValueCurr != EMPTY_VALUE) && (hmaBearishValueCurr == EMPTY_VALUE)) { 
            
               Print("...Bullish @ " + convertCurrentTimeToString() ); 
            } 
            else if( (hmaBearishValueCurr != EMPTY_VALUE) && (hmaBullishValueCurr != EMPTY_VALUE)) { 
               
               Print("...Bearish @ " + convertCurrentTimeToString() );
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
/** End - NON_LINEAR_KALMAN Level and slope*/

/** Start - KALMAN_BANDS Level and slope*/
/**
 * Retrieve the KALMAN_BANDS given buffer value and barIndex
 *
 * 0 = KALMAN_BAND_MIDDLE
 * 1 = KALMAN_BAND_UPPER
 * 2 = KALMAN_BAND_LOWER
 */
double getKalmanBandsLevel(int length, int buffer, int barIndex) {
   
   int     preSmooth      =  1;
   double  kSigma        =  0.5;   
   return NormalizeDouble(iCustom(Symbol(), Period(), KALMAN_BANDS, length, preSmooth, kSigma, buffer, barIndex), Digits);
}
Slope getKalmanBandsSlope(int length, int barIndex) {
   
   double current = getKalmanBandsLevel(length, KALMAN_BAND_MIDDLE, barIndex);
   double previous = getKalmanBandsLevel(length, KALMAN_BAND_MIDDLE, getPreviousBarIndex(barIndex));
   
   if( current > previous) {
      
      return BULLISH_SLOPE;
   }
   else if(current < previous){
      
      return BEARISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;
}
/** End - KALMAN_BANDS Level and slope*/

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

/** Start - POLIFIT_BANDS Level*/
/**
 * Retrieve the SUPER_TREND given buffer value
 *
 * 0 = Main, never empty
 * 1 = For both Up and down trend
 *   : EMPTY_VALUE=>  Up trend
 *   : NOT EMPTY  =>  Down trend
 */
double getSuperTrendLeve_TODO(int buffer, int barIndex) {
   
   int     length       =  1;  
   double  multiplier   =  1;  
   return NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, CURRENT_TIMEFRAME, length, multiplier, buffer, barIndex), Digits);
}
/** End - SUPER_TREND Level*/

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
 * 0 = SE_BAND_MAIN(Middle): never empty
 * 1 = SE_BAND_UPPER: never empty
 * 2 = SE_BAND_LOWER: never empty
 */
double getSeBandsLevel(int length, int buffer, int barIndex) {
   
   int smoothingLength        = 3;
   return NormalizeDouble(iCustom(Symbol(), Period(), SE_BANDS, length, smoothingLength, buffer, barIndex), Digits);
}
/** End - SE_BANDS Level*/

/** Start - VIDYA_ZONES Level*/
/**
 * Retrieve the VIDYA_ZONES given buffer value and barIndex
 *
 * 0 = VIDYA_ZONE_UPPER: never empty
 * 1 = VIDYA_ZONE_MIDDLE: never empty
 * 2 = VIDYA_ZONE_LOWER: never empty
 */
double getVidyaZonesLevel(int cmoPeriod, int smoothPeriod, int buffer, int barIndex) {
   
   return NormalizeDouble(iCustom(Symbol(), Period(), VIDYA_ZONES, cmoPeriod, smoothPeriod, buffer, barIndex), Digits);
}
/** End - VIDYA_ZONES Level*/

/** Start - FLOATED_KAUFMAN_RSI Level*/
/**
 * Retrieve the FLOATED_KAUFMAN_RSI given buffer value and barIndex
 *
 * 0 = FLOATED_KAUFMAN_RSI_LEVEL_SIGNAL
 * 3 = FLOATED_KAUFMAN_RSI_LEVEL_UPPER
 * 4 = FLOATED_KAUFMAN_RSI_LEVEL_MIDDLE
 * 5 = FLOATED_KAUFMAN_RSI_LEVEL_LOWER 
 */
double getRsiOfKaufmanLevel(int buffer, int barIndex) {
   
   int rsiPeriod     = 10;
   int amaPeriod     = 10;
   int fastEnd       = 1;
   int slowEnd       = 34;
   int smoothPower   = 2;
   int minMaxPeriod  = 35;

   return NormalizeDouble(iCustom(Symbol(), Period(), FLOATED_KAUFMAN_RSI, rsiPeriod, amaPeriod, fastEnd, slowEnd, smoothPower, minMaxPeriod, buffer, barIndex), Digits);
}
/** End - FLOATED_KAUFMAN_RSI Level*/


/** Start - DYNAMIC_RSX_OMA Level, Slope, Extremes, and Reversal*/
/**
 * Retrieve the DYNAMIC_RSX_OMA given buffer value and barIndex
 *
 * DYNAMIC_RSX_OMA_SIGNAL = 0
 * DYNAMIC_RSX_OMA_LOWER  = 1
 * DYNAMIC_RSX_OMA_UPPER  = 2
 * DYNAMIC_RSX_OMA_MIDDLE = 3
 */
double getDynamicRsxOmaLevel(int buffer, int barIndex) {
   
   int    rsxLength     = 9;
   int    price         = 0;
   int    omaLength     = 2;
   double omaSpeed      = 1;
   bool   omaAdaptive   = true;
   int    lookBackBars  = 35;
   return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_RSX_OMA, rsxLength, price, omaLength, omaSpeed, omaAdaptive, lookBackBars, buffer, barIndex), Digits);
}
Slope getDynamicRsxOmaLevelSlope() {
   
   double signalCurr    = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
   double signalPrev    = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, getPreviousBarIndex(1));
   
   if(signalCurr > signalPrev) {
   
      return BULLISH_SLOPE;
   }
   else if(signalCurr < signalPrev){
      
      return BEARISH_SLOPE;
   }
   else {
      
      return UNKNOWN_SLOPE;
   }   
}
Zones getDynamicRsxOmaExtremeZone(int barIndex) {

   if( (barIndex > 0) && (latestDynamicRsxOmaExtremeZoneTime == getCurrentTime()) ) {      
      
      //If we checking previous close - then only check once as the status will never change
      return latestDynamicRsxOmaExtremeZone;
   } 
   
   double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, barIndex);
   double upperLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, barIndex);
   double lowerLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, barIndex);
   
   if(signalLevel > upperLevel) {
      
      latestDynamicRsxOmaExtremeZone       = BULLISH_EXTREME_ZONE;
      latestDynamicRsxOmaExtremeZoneTime   = getCurrentTime();        
      return BULLISH_EXTREME_ZONE;
   }
   else if(signalLevel < lowerLevel) {
      
      latestDynamicRsxOmaExtremeZone       = BEARISH_EXTREME_ZONE;
      latestDynamicRsxOmaExtremeZoneTime   = getCurrentTime();
      return BEARISH_EXTREME_ZONE;
   } 
   /*else if( (signalLevel < upperLevel) && (signalLevel > lowerLevel) ) {
      
      return RANGING_ZONE;
   }*/     

   return latestDynamicRsxOmaExtremeZone;
}
/**
 * Pre-Conditions: Previous bar should have been closed on extreme zones
 *
 */
Reversal getDynamicRsxOmaExtremeZoneReversal(bool checkPreviousBarClose) {
      
   if(latestDynamicRsxOmaExtremeZoneReversalTime == getCurrentTime()) {
      
      return latestDynamicRsxOmaExtremeZoneReversal;
   }
   
   int extremeBarIndex = 0;
   if(checkPreviousBarClose) {
      extremeBarIndex = 2;
   }
   else {
      extremeBarIndex = 1;
   }
   
   Zones zone = getDynamicRsxOmaExtremeZone(extremeBarIndex);
   
   if(zone == BULLISH_EXTREME_ZONE) {
      
      if(checkPreviousBarClose) {
         
         double signalLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
         double upperLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, CURRENT_BAR);
         
         double signalLevelPrev = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, getPreviousBarIndex(CURRENT_BAR));
         double upperLevelPrev = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, getPreviousBarIndex(CURRENT_BAR));
        
         if( (signalLevelCurr < upperLevelCurr) && (signalLevelPrev < upperLevelPrev)) {

            latestDynamicRsxOmaExtremeZoneReversal       = BEARISH_REVERSAL;
            latestDynamicRsxOmaExtremeZoneReversalTime   = getCurrentTime();
            
            //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
            invalidateDynamicRsxOmaExtremeZoneOnReversal();          
            
            return BEARISH_REVERSAL;
         }          
         
      } 
      else {
         
         double signalLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
         double upperLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, CURRENT_BAR);
         
         if(signalLevelCurr < upperLevelCurr) {

            latestDynamicRsxOmaExtremeZoneReversal       = BEARISH_REVERSAL;
            latestDynamicRsxOmaExtremeZoneReversalTime   = getCurrentTime();
            
            //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
            invalidateDynamicRsxOmaExtremeZoneOnReversal();            
            
            return BEARISH_REVERSAL;
         }       
      } 

      
   }
   else if(zone == BEARISH_EXTREME_ZONE) {
     
      if(checkPreviousBarClose) {
        
         double signalLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
         double lowerLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, CURRENT_BAR);
         
         double signalLevelPrev = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, getPreviousBarIndex(CURRENT_BAR));
         double lowerLevelPrev = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, getPreviousBarIndex(CURRENT_BAR)); 
         
         if( (signalLevelCurr > lowerLevelCurr) && (signalLevelPrev > lowerLevelPrev)) {
            
            latestDynamicRsxOmaExtremeZoneReversal       = BULLISH_REVERSAL;
            latestDynamicRsxOmaExtremeZoneReversalTime   = getCurrentTime();             
            return BULLISH_REVERSAL;
         }          
         
      } 
      else {
          
         double signalLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
         double lowerLevelCurr = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, CURRENT_BAR);
         
         if(signalLevelCurr > lowerLevelCurr) {

            latestDynamicRsxOmaExtremeZoneReversal       = BULLISH_REVERSAL;
            latestDynamicRsxOmaExtremeZoneReversalTime   = getCurrentTime();             
            return BULLISH_REVERSAL;
         }
      }      
     
   }   

   return latestDynamicRsxOmaExtremeZoneReversal;       
}
/** End - DYNAMIC_RSX_OMA Level, Slope, Extremes, and Reversal*/

/** Start - FLOATED_STEPPED_RSI Level, slope, zones, and reversal*/
/**
 * Retrieve the FLOATED_STEPPED_RSI given buffer value and barIndex
 *
 * FLOATED_STEPPED_RSI_FAST    = 0;
 * FLOATED_STEPPED_RSI_SLOW    = 1;
 * FLOATED_STEPPED_RSI_SIGNAL  = 2; 
 * FLOATED_STEPPED_RSI_UPPER   = 5;
 * FLOATED_STEPPED_RSI_MIDDLE  = 6;
 * FLOATED_STEPPED_RSI_LOWER   = 7;
 */
double getStepRSIFloatingLevel(int rsiPeriod, int fastStepSize, int slowStepSize, int minMaxPeriod,  int buffer, int barIndex) {
   
   return NormalizeDouble(iCustom(Symbol(), Period(), FLOATED_STEPPED_RSI, rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, buffer, barIndex), Digits);
}
Slope getStepRSIFloatingSlope(int barIndex) {

   double signalLevel = getStepRSIFloatingLevel(10, 10, 15, 49, FLOATED_STEPPED_RSI_SIGNAL, CURRENT_BAR);
   double fastLevel = getStepRSIFloatingLevel(10, 10, 15, 49, FLOATED_STEPPED_RSI_FAST, CURRENT_BAR); 
   double slowLevel = getStepRSIFloatingLevel(10, 10, 15, 49, FLOATED_STEPPED_RSI_SLOW, CURRENT_BAR);

   if(signalLevel > fastLevel && signalLevel > slowLevel) {
              
      return BULLISH_SLOPE;
   }
   else if(signalLevel < fastLevel && signalLevel < slowLevel) {
      
      return BEARISH_SLOPE;
   } 
  
   return UNKNOWN_SLOPE;
}
Zones getStepRSIFloatingExtremeZone(int rsiPeriod, int fastStepSize, int slowStepSize, int minMaxPeriod, int barIndex) {

   if(latestStepRSIFloatingExtremeZoneTime == getCurrentTime()) {      
      
      return latestStepRSIFloatingExtremeZone;
   } 
   
   double signalLevel = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, barIndex);
   double upperLevel = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_UPPER, barIndex);
   double lowerLevel = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_LOWER, barIndex);
   
   if(signalLevel > upperLevel) {
      
      latestStepRSIFloatingExtremeZone       = BULLISH_EXTREME_ZONE;
      latestStepRSIFloatingExtremeZoneTime   = getCurrentTime();        
      return BULLISH_EXTREME_ZONE;
   }
   else if(signalLevel < lowerLevel) {
      
      latestStepRSIFloatingExtremeZone       = BEARISH_EXTREME_ZONE;
      latestStepRSIFloatingExtremeZoneTime   = getCurrentTime();      
      return BEARISH_EXTREME_ZONE;
   } 
   else if( (signalLevel < upperLevel) && (signalLevel > lowerLevel) ) {
      
      return RANGING_ZONE;
   }     
   return NORMAL_ZONE;
}
//TODO: TEST
Reversal getStepRSIFloatingExtremeZoneReversal(bool checkPreviousBarClose) {
  
   int rsiPeriod = 10;
   int fastStepSize=10;
   int slowStepSize = 15;
   int minMaxPeriod= 49;

   if(latestStepRSIFloatingExtremeZoneReversalTime == getCurrentTime()) {
      return latestStepRSIFloatingExtremeZoneReversal;
   } 
   
   if(latestStepRSIFloatingExtremeZone == BULLISH_EXTREME_ZONE) {
   
      if(checkPreviousBarClose) {
         
         double signalCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, CURRENT_BAR);
         double signalPrev = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, getPastBars(1));
         double upperLevelCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_UPPER, CURRENT_BAR);
         double upperLevelPrev = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_UPPER, getPastBars(1));
         
         if( (signalCurr < upperLevelCurr) && (signalPrev < upperLevelPrev) ) {
            
            latestStepRSIFloatingExtremeZoneReversal = BEARISH_REVERSAL;
            latestStepRSIFloatingExtremeZoneReversalTime = getCurrentTime();             
            return BEARISH_REVERSAL;
         }         
      }
      else {
         
         double signalCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, CURRENT_BAR);
         double upperLevelCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_UPPER, CURRENT_BAR);
         
         if(signalCurr < upperLevelCurr) {
            
            latestStepRSIFloatingExtremeZoneReversal = BULLISH_REVERSAL;
            latestStepRSIFloatingExtremeZoneReversalTime = getCurrentTime();             
            return BULLISH_REVERSAL;
         }                  
      }           
   }
   else if(latestStepRSIFloatingExtremeZone == BEARISH_EXTREME_ZONE) {
      
      if(checkPreviousBarClose) {
         
         double signalCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, CURRENT_BAR);
         double signalPrev = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, getPastBars(1));
         double lowerLevelCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_LOWER, CURRENT_BAR);
         double lowerLevelPrev = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_LOWER, getPastBars(1));
         
         if( (signalCurr > lowerLevelCurr) && (signalPrev > lowerLevelPrev) ) {
            
            latestStepRSIFloatingExtremeZoneReversal = BULLISH_REVERSAL;
            latestStepRSIFloatingExtremeZoneReversalTime = getCurrentTime();            
            return BULLISH_REVERSAL;
         }         
      }
      else {
         
         double signalCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_SIGNAL, CURRENT_BAR);
         double lowerLevelCurr = getStepRSIFloatingLevel(rsiPeriod, fastStepSize, slowStepSize, minMaxPeriod, FLOATED_STEPPED_RSI_LOWER, CURRENT_BAR);
         
         if(signalCurr > lowerLevelCurr) {
            
            latestStepRSIFloatingExtremeZoneReversal = BULLISH_REVERSAL;
            latestStepRSIFloatingExtremeZoneReversalTime = getCurrentTime();            
            return BULLISH_REVERSAL;
         }         
         
      }      
   }   

   return latestStepRSIFloatingExtremeZoneReversal;       
}
//TODO: Fix Prev and Curr slopes always same
Reversal getStepRSIFloatingSlopeReversal(bool checkPreviousBarClose) {
  

   if(latestStepRSIFloatingReversalTime == getCurrentTime()) {
      return latestStepRSIFloatingReversal;
   } 
   
   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getStepRSIFloatingSlope(CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getStepRSIFloatingSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getStepRSIFloatingSlope(barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getStepRSIFloatingSlope(getPreviousBarIndex(CURRENT_BAR) );
      
      //Check if current and previous slopes changed direction      
      if(  (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            )  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if( (latestStepRSIFloatingReversal != BULLISH_REVERSAL) && (slopeCurr == BULLISH_SLOPE) && slopeForOppositeDirectionVerification == BEARISH_SLOPE) {
            
            //Print("AT BULLISH");
            
            //Print("SLOPE is " + slopeCurr + " at " + getCurrentTime());
            //Print("SLOPE was " + slopeForOppositeDirectionVerification + " at " + latestSomat3ReversalTime);            
            
            latestStepRSIFloatingReversal = BULLISH_REVERSAL;
            latestStepRSIFloatingReversalTime = getCurrentTime();


            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_REVERSAL;
         }         
         else if( (latestSomat3Reversal != BEARISH_REVERSAL) && (slopeCurr == BEARISH_SLOPE)  && slopeForOppositeDirectionVerification == BULLISH_SLOPE) {
            
            //Print("AT BEARISH"); 

            //Print("SLOPE is " + slopeCurr + " at " + getCurrentTime());
            //Print("SLOPE was " + slopeForOppositeDirectionVerification + " at " + latestSomat3ReversalTime);             
            
            latestStepRSIFloatingReversal = BEARISH_REVERSAL;
            latestStepRSIFloatingReversalTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_REVERSAL;
         } 
         else {
            
            //Print("Here" + slopeCurr);
         }            
      }
      else {
         
         //Print("Here" + slopeCurr);
      }   
   }
   else {
   
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the getStepRSIFloatingSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getStepRSIFloatingSlope(barIndexForOppositeDirectionVerification);

      //Check if current and previous slopes changed direction      
      if( slopeForOppositeDirectionVerification != slopeCurr)  {// Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
         
         if(slopeCurr == BULLISH_SLOPE) {
         
            latestStepRSIFloatingReversal = BULLISH_REVERSAL;
            latestStepRSIFloatingReversalTime = getCurrentTime();   

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_REVERSAL;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestStepRSIFloatingReversal = BEARISH_REVERSAL;
            latestStepRSIFloatingReversalTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_REVERSAL;
         }             
      }     
      
   }

   return latestStepRSIFloatingReversal;       
}
/** End - FLOATED_STEPPED_RSI Level, slope, zones, and reversal*/

/** Start - BB_STOCH_OF_RSI Level and Slope*/
/**
 * Retrieve the BB_STOCH_OF_RSI given buffer value and barIndex
 *
 * 0 = SE_BAND_MAIN(Middle): never empty
 * 1 = SE_BAND_UPPER: never empty
 * 2 = SE_BAND_LOWER: never empty
 */
double getBBnStochOfRsiLevel(int buffer, int barIndex) {
   
   //Stochastic
   int kPeriod            =  20;//9; //21         20
   int dPeriod            =  10;//6; //8          10
   int slowing            =  5;//9; //5 or 3     5
  
   //Bollinger Bands
   int bandsPeriod        =  5;
   int bandsShift         =  0;
   double bandsDeviations =  0.5;
   
   //RSI
   int rSIPeriod          =  4;
   return NormalizeDouble(iCustom(Symbol(), Period(), BB_STOCH_OF_RSI, 
   
                           //Stochastic
                           kPeriod, dPeriod, slowing, 
                           
                           //Bollinger Bands
                           bandsPeriod, bandsShift, bandsDeviations,
                           //RSI
                           rSIPeriod,
                           
                           buffer, barIndex), Digits);
}
Slope getBBnStochOfRsiSlope(int barIndex) {
   
   double stochLevel    = getBBnStochOfRsiLevel(BB_STOCH_OF_RSI_STOCH, barIndex);
   double bbUpperLevel  = getBBnStochOfRsiLevel(BB_STOCH_OF_RSI_BB_UPPER, barIndex);
   double bbLowerLevel  = getBBnStochOfRsiLevel(BB_STOCH_OF_RSI_BB_LOWER, barIndex);
   
   if(stochLevel > bbUpperLevel) {
   
      return BULLISH_SLOPE;
   }
   else if(stochLevel < bbLowerLevel){
      
      return BEARISH_SLOPE;
   }
   else {
      
      return UNKNOWN_SLOPE;
   }   
}
/** End - BB_STOCH_OF_RSI Level and Slope*/

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
 * 2 = Bearish value, empty when in Bullish mode
 */
double getSomat3Level(int buffer, int barIndex) {
   
   int timeFrame              = Period(); 
   int length                 = 10;
   double sensitivityFactor_  = 0.5;
   return NormalizeDouble(iCustom(Symbol(), Period(), SOMAT3, timeFrame, length, sensitivityFactor_, buffer, barIndex), Digits);
}
Slope getSomat3Slope(int barIndex) {
   
   int slope = (int)getSomat3Level(SOMAT3_SLOPE, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
   
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
/** End - SOMAT3 Level and slope*/


/** Start - DYNAMIC_STEPMA_PDF Level and slope*/
/**
 * Retrieve the DYNAMIC_STEPMA_PDF given buffer value and barIndex
 *
 * DYNAMIC_STEPMA_PDF_SLOPE = 1;//EMPTY_VALUE = BEARISH, EMPTY_VALUE != BULLISH
 * DYNAMIC_STEPMA_PDF_UPPER = 3;
 * DYNAMIC_STEPMA_PDF_LOWER = 4;
 */
double getDynamicStepMaPdfLevel(int pdfMaLength, int pdfStepSize, int buffer, int barIndex) {
   
   double  sensitivity        = 10;
   double  variance           = 5;
   double  mean               = 0.0;
   return NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_STEPMA_PDF, pdfMaLength, pdfStepSize, sensitivity, variance, mean, buffer, barIndex), Digits);
}
Slope getDynamicStepMaPdfSlope(int pdfMaLength, int pdfStepSize, int barIndex) {
   
   double slope = getDynamicStepMaPdfLevel(pdfMaLength, pdfStepSize, DYNAMIC_STEPMA_PDF_SLOPE, barIndex);   
   if(slope == EMPTY_VALUE) {
      
      return BULLISH_SLOPE;
   }
   else if( slope != EMPTY_VALUE) {
      
      return BEARISH_SLOPE;
   }   
      
   return UNKNOWN_SLOPE;
}
Cross getDynamicStepMaPdfCross(int pdfMaLength, int fastPdfStepSize, int slowPdfStepSize, int barIndex) {

   //Only check once per bar
   if(latestDynamicStepMaPdfCrossTime == getCurrentTime()) {      
      
      return latestDynamicStepMaPdfCross;
   }

   double fastMaValue = getDynamicStepMaPdfLevel(pdfMaLength, fastPdfStepSize, DYNAMIC_STEPMA_PDF_SIGNAL, barIndex);
   double slowMaValue = getDynamicStepMaPdfLevel(pdfMaLength, slowPdfStepSize, DYNAMIC_STEPMA_PDF_SIGNAL, barIndex);
   if(fastMaValue > slowMaValue) {
      
      latestDynamicStepMaPdfCross      = BULLISH_CROSS;
      latestDynamicStepMaPdfCrossTime  = getCurrentTime();
      return BULLISH_CROSS;
   }
   else if( fastMaValue < slowMaValue) {
      
      latestDynamicStepMaPdfCross      = BEARISH_CROSS;
      latestDynamicStepMaPdfCrossTime  = getCurrentTime();
      return BEARISH_CROSS;
   }   
      
   return latestDynamicStepMaPdfCross;
}
/** End - DYNAMIC_STEPMA_PDF Level and slope*/

/** Start - STEPPED_TTA Level and slope*/
/**
 * Retrieve the STEPPED_TTA given buffer value and barIndex
 *
 * 0 = STEPPED_TTA_MAIN
 * 3 = STEPPED_TTA_SLOPE value. EMPTY_VALUE when in BULLISH_SLOPE, !=EMPTY_VALUE when BEARISH_SLOPE
 */
double getSteppedTtaLevel(int filterPeriod, int filterHot, int buffer, int barIndex) {
   
   return NormalizeDouble(iCustom(Symbol(), Period(), STEPPED_TTA, filterPeriod, filterHot, buffer, barIndex), Digits);
}
Slope getSteppedTtaSlope(int filterPeriod, int filterHot, int barIndex) {
   
   double bearishSlope = getSteppedTtaLevel(filterPeriod, filterHot, STEPPED_TTA_SLOPE, barIndex);
   if( (bearishSlope != EMPTY_VALUE)) {
      
      return BEARISH_SLOPE;
   }
   else {
      
      return BULLISH_SLOPE;
   }
}
/** End - STEPPED_TTA Level and slope*/

/** Start - SUPER_TREND Level and slope*/
/**
 * Retrieve the SUPER_TREND given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = For both Up and down trend
 *   : EMPTY_VALUE=>  Up trend
 *   : NOT EMPTY  =>  Down trend
 */
double getSuperTrendLevel(int buffer, int barIndex) {
   
   int     length       =  2;  
   double  multiplier   =  1;  
   return NormalizeDouble(iCustom(Symbol(), Period(), SUPER_TREND, CURRENT_TIMEFRAME, length, multiplier, buffer, barIndex), Digits);
}
Slope getSuperTrendSlope(int barIndex) {

   double bearishSlope = getSuperTrendLevel(SUPER_TREND_BEARISH_SLOPE, barIndex);
   
   if( (bearishSlope != EMPTY_VALUE)) {
      
      return BEARISH_SLOPE;
   }
   else {
      
      return BULLISH_SLOPE;
   }
}
/** End - SUPER_TREND Level and slope*/

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
   if(latestDynamicOfAveragesShortTermTrendTime == getCurrentTime()) {      
      
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
      latestDynamicOfAveragesShortTermTrendTime = getCurrentTime();    
      return BULLISH_SHORT_TERM_TREND;
   }
   else if( (latestDynamicOfAveragesShortTermTrend != BEARISH_SHORT_TERM_TREND) 
         && ((signalCurr < midLevelCurr ) && (signalCurr < midLevelPrev)) ) {
      
      latestDynamicOfAveragesShortTermTrend = BEARISH_SHORT_TERM_TREND;
      latestDynamicOfAveragesShortTermTrendTime = getCurrentTime();       
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
   int dzLookBack =  12;
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
double getJurikFilterLevel(int length, int buffer, int barIndex) {
   
   int timeFrame  =  Period(); 
   double phase   =  100;             
   int price      =  21; //Zero based, pr_hatbiased2;    
   double filter  =  1; 
   int filterType =  2; //Apply filter to all
   
   return NormalizeDouble(iCustom(Symbol(), Period(), JURIK_FILTER, timeFrame, length, phase, price, filter, filterType, buffer, barIndex), Digits);
}
/**
 *  Get the JURIK_FILTER Slope(5). Upward = 1, Downward = -1.
 */
Slope getJurikFilterSlope(int length, int barIndex) {

   int slope = (int)getJurikFilterLevel(length, JURIK_FILTER_SLOPE, barIndex);//It is safe to explictly cast to int as the slope is either Upward = 1, or Downward = -1.
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

/** Start - POLYFIT_BANDS Level*/
/**
 * Retrieve the POLYFIT_BANDS given buffer value and barIndex
 *
 * 0 = POLYFIT_BAND_MAIN(Middle), Never empty.
 * 1 = POLYFIT_BAND_FIRST_UPPER, Never empty
 * 2 = POLYFIT_BAND_FIRST_LOWER, Never empty
 * 5 = POLYFIT_BAND_SECOND_UPPER, Never empty
 * 6 = POLYFIT_BAND_SECOND_LOWER, Never empty
 */
double getPolyfitBandsLevel(int length, int buffer, int barIndex) {
  
   int preSmooth     = 2;   
   int preSmoothMode = 0;   
   return NormalizeDouble(iCustom(Symbol(), Period(), POLYFIT_BANDS, length, preSmooth, preSmoothMode, buffer, barIndex), Digits);
}
/** End - POLYFIT_BANDS Level*/

/** Start - RSIOMA_BANDS Level, zones and slope*/
/**
 * Retrieve the RSIOMA_BANDS given buffer value and barIndex
 *
 * 0 = RSIOMA_BANDS_SIGNAL(Upper Band), Never empty.
 * 1 = RSIOMA_BANDS_UPPER, Never empty
 * 2 = RSIOMA_BANDS_LOWER. Empty when Bearish.
 * 3 = RSIOMA_BANDS_MA. Empty when Bullish. 
 * 4 = RSIOMA_BANDS_SLOPE. Empty when Bullish, Not Empty when Bearish.  
 */
double getRsiomaBandsLevel(int length, int buffer, int barIndex) {
   
   double          omaSpeed   = 5.0;    
   int             maPeriod   = 34;
   ENUM_MA_METHOD  maMethod   = 3;
   return NormalizeDouble(iCustom(Symbol(), Period(), RSIOMA_BANDS, length, omaSpeed, maPeriod, maMethod, buffer, barIndex), Digits);
}
/**
 *  Get the RSIOMA_BANDS Slope(4). Upward = EMPTY_VALUE, Downward = !EMPTY_VALUE.
 */
Slope getRsiomaBandsSlope(int length, int barIndex) {

   double slope = getRsiomaBandsLevel(length, RSIOMA_BANDS_SLOPE, barIndex);
   
   if( slope != EMPTY_VALUE) {
      
      return BEARISH_SLOPE;
   }
   else if(slope == EMPTY_VALUE) {
      
      return BULLISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;
}
Zones getRsiomaBandsZones(int length, int barIndex) {

   if(latestRsiomaBandsZoneTime == getCurrentTime()) {      
      
      return latestRsiomaBandsZone;
   } 
   
   double signalLevel = getRsiomaBandsLevel(length, RSIOMA_BANDS_SIGNAL, barIndex);
   double upperLevel = getRsiomaBandsLevel(length, RSIOMA_BANDS_UPPER, barIndex);
   double lowerLevel = getRsiomaBandsLevel(length, RSIOMA_BANDS_LOWER, barIndex);
   
   if(signalLevel > upperLevel) {
      
      latestRsiomaBandsZone      = BULLISH_ZONE;
      latestRsiomaBandsZoneTime  = getCurrentTime();        
      return BULLISH_ZONE;
   }   
   else if(signalLevel < lowerLevel) {
      
      latestRsiomaBandsZone      = BEARISH_ZONE;
      latestRsiomaBandsZoneTime  = getCurrentTime();        
      return BEARISH_ZONE;
   }   
   else if((signalLevel < upperLevel) && (signalLevel > lowerLevel)) {
      
      latestRsiomaBandsZone     = TRANSITION_ZONE;
      latestRsiomaBandsZoneTime = getCurrentTime();        
      return TRANSITION_ZONE;
   }
   
   return latestRsiomaBandsZone;
}
/**
 * Pre-Conditions: Previous zone should have been opposite
 *
 */
Reversal getRsiomaBandsZoneReversal(int length, bool checkPreviousBarClose) {

   if(latestRsiomaBandsZoneReversalTime == getCurrentTime()) {
      
      return latestRsiomaBandsZoneReversal;
   }
   
   int previousZoneBarIndex = 0;
   if(checkPreviousBarClose) {
      previousZoneBarIndex = 2;
   }
   else {
      previousZoneBarIndex = 1;
   }
   
   Zones zone = getRsiomaBandsZones(length, previousZoneBarIndex);
   
   Print("Zone at bar: " + previousZoneBarIndex + "is " + getZoneDescription(zone) );
   
   if(zone == BULLISH_ZONE) {
      
      if(checkPreviousBarClose) {
      
         Zones zonePrevOne = getRsiomaBandsZones(length, getPreviousBarIndex(CURRENT_BAR));
         Zones zonePrevTwo = getRsiomaBandsZones(length, previousZoneBarIndex);
        
         if( (zonePrevTwo == BEARISH_ZONE || zonePrevTwo == TRANSITION_ZONE) && ((zonePrevOne == BULLISH_ZONE || zonePrevOne == BULLISH_ZONE)) ) {

            latestRsiomaBandsZoneReversal       = BULLISH_REVERSAL;
            latestRsiomaBandsZoneReversalTime   = getCurrentTime();
            
            return BULLISH_REVERSAL;
         }          
         
      } 
      else {

         Zones zonePrev = getRsiomaBandsZones(length, previousZoneBarIndex);
         if(zonePrev == BEARISH_ZONE || zonePrev == TRANSITION_ZONE) {

            latestRsiomaBandsZoneReversal       = BULLISH_REVERSAL;
            latestRsiomaBandsZoneReversalTime   = getCurrentTime();
            
            return BULLISH_REVERSAL;
         }                       
      } 
      
   }
   else if(zone == BEARISH_ZONE) {
     
      if(checkPreviousBarClose) {
        
         Zones zonePrevOne = getRsiomaBandsZones(length, getPreviousBarIndex(CURRENT_BAR));
         Zones zonePrevTwo = getRsiomaBandsZones(length, previousZoneBarIndex);
         
         if( (zonePrevTwo == BULLISH_ZONE || zonePrevTwo == TRANSITION_ZONE) && ((zonePrevOne == BEARISH_ZONE || zonePrevOne == BEARISH_ZONE)) ) {
            
            latestRsiomaBandsZoneReversal       = BEARISH_REVERSAL;
            latestRsiomaBandsZoneReversalTime   = getCurrentTime(); 
                        
            return BEARISH_REVERSAL;
         }          
         
      } 
      else {
          
         Zones zonePrev = getRsiomaBandsZones(length, previousZoneBarIndex);

         if(zonePrev == BULLISH_ZONE || zonePrev == TRANSITION_ZONE) {

            latestRsiomaBandsZoneReversal       = BEARISH_REVERSAL;
            latestRsiomaBandsZoneReversalTime   = getCurrentTime(); 

            return BEARISH_REVERSAL;
         }
      }      
     
   }   

   return latestRsiomaBandsZoneReversal;       
}
/** End - RSIOMA_BANDS Level, zones, slope, and reversal*/

/** Start - CYCLE_KROUFR_VERSION Level, zones and slope*/
/**
 * Retrieve the CYCLE_KROUFR_VERSION given buffer value and barIndex
 *
 * 0 = CYCLE_KROUFR_VERSION_SIGNAL
 * 
 * Zones
 * 10 = CYCLE_KROUFR_VERSION_OVERSOLD_LEVEL
 * 90 = CYCLE_KROUFR_VERSION_OVERBOUGHT_LEVEL
 */
double getCycleKroufRLevel(int fastMa, int slowMa, int crosses, int buffer, int barIndex) {
   
   return NormalizeDouble(iCustom(Symbol(), Period(), CYCLE_KROUFR_VERSION, fastMa, slowMa, crosses, buffer, barIndex), Digits);
}
/**
 *  Get the CYCLE_KROUFR_VERSION Slope
 */
Slope getCycleKroufRLevelSlope(int fastMa, int slowMa, int crosses) {

   double signalCurr = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, CURRENT_BAR);
   double signalPrev = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, getPreviousBarIndex(CURRENT_BAR));
   
   if( signalCurr > signalPrev) {
      
      return BULLISH_SLOPE;
   }
   else if(signalCurr < signalPrev) {
      
      return BEARISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;
}
Zones getCycleKroufrExtremeZone(int fastMa, int slowMa, int crosses, int barIndex) {

   if(latestCycleKroufrExtremeZoneTime == getCurrentTime()) {      
      
      return latestCycleKroufrExtremeZone;
   } 
   
   double signalCurr = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, barIndex);
   
   if( signalCurr > CYCLE_KROUFR_VERSION_OVERBOUGHT_LEVEL) {
      
      latestCycleKroufrExtremeZone     = BULLISH_EXTREME_ZONE;
      latestCycleKroufrExtremeZoneTime = getCurrentTime();        
      return BULLISH_EXTREME_ZONE;
   }   
   else if(signalCurr < CYCLE_KROUFR_VERSION_OVERSOLD_LEVEL) {
      
      latestCycleKroufrExtremeZone     = BEARISH_EXTREME_ZONE;
      latestCycleKroufrExtremeZoneTime = getCurrentTime();        
      return BEARISH_EXTREME_ZONE;      
   }   

   return UNKNOWN_ZONE;
}
/**
 * Pre-Conditions: Previous bar should have been closed on extreme zones
 *
 */
Reversal getCycleKroufrExtremeZoneReversal(int fastMa, int slowMa, int crosses, bool checkPreviousBarClose) {
      
   if(latestCycleKroufrExtremeZoneReversalTime == getCurrentTime()) {
      
      return latestCycleKroufrExtremeZoneReversal;
   }
   
   int extremeBarIndex = 0;
   if(checkPreviousBarClose) {
      extremeBarIndex = 2;
   }
   else {
      extremeBarIndex = 1;
   }
   
   Zones zone = getCycleKroufrExtremeZone(fastMa, slowMa, crosses, extremeBarIndex);
   
   if(zone == BULLISH_EXTREME_ZONE) {
      
      if(checkPreviousBarClose) {
      
         double signalLevelCurr = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, CURRENT_BAR);
         double signalLevelPrev = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, getPreviousBarIndex(CURRENT_BAR));
        
         if( (signalLevelCurr < CYCLE_KROUFR_VERSION_OVERBOUGHT_LEVEL) && (signalLevelPrev < CYCLE_KROUFR_VERSION_OVERBOUGHT_LEVEL)) {

            latestCycleKroufrExtremeZoneReversal       = BEARISH_REVERSAL;
            latestCycleKroufrExtremeZoneReversalTime   = getCurrentTime();
            
            //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
            invalidateCycleKroufrExtremeZoneOnReversal();          
            
            return BEARISH_REVERSAL;
         }          
         
      } 
      else {
         
         double signalLevelCurr = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, CURRENT_BAR);
         
         if(signalLevelCurr < CYCLE_KROUFR_VERSION_OVERBOUGHT_LEVEL) {

            latestCycleKroufrExtremeZoneReversal       = BEARISH_REVERSAL;
            latestCycleKroufrExtremeZoneReversalTime   = getCurrentTime();
            
            //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
            invalidateCycleKroufrExtremeZoneOnReversal();            
            
            return BEARISH_REVERSAL;
         }       
      } 

      
   }
   else if(zone == BEARISH_EXTREME_ZONE) {
     
      if(checkPreviousBarClose) {
        
         double signalLevelCurr = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, CURRENT_BAR);
         double signalLevelPrev = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, getPreviousBarIndex(CURRENT_BAR));
         
         if( (signalLevelCurr > CYCLE_KROUFR_VERSION_OVERSOLD_LEVEL) && (signalLevelPrev > CYCLE_KROUFR_VERSION_OVERSOLD_LEVEL)) {
            
            latestCycleKroufrExtremeZoneReversal       = BULLISH_REVERSAL;
            latestCycleKroufrExtremeZoneReversalTime   = getCurrentTime(); 
            
            //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
            invalidateCycleKroufrExtremeZoneOnReversal();    
                        
            return BULLISH_REVERSAL;
         }          
         
      } 
      else {
          
         double signalLevelCurr = getCycleKroufRLevel(fastMa, slowMa, crosses, CYCLE_KROUFR_VERSION_SIGNAL, CURRENT_BAR);
         
         if(signalLevelCurr > CYCLE_KROUFR_VERSION_OVERSOLD_LEVEL) {

            latestCycleKroufrExtremeZoneReversal       = BULLISH_REVERSAL;
            latestCycleKroufrExtremeZoneReversalTime   = getCurrentTime(); 

            //Invalidate the extreme zone after giving the signal as the signal must be back inside the bands
            invalidateCycleKroufrExtremeZoneOnReversal();                
                        
            return BULLISH_REVERSAL;
         }
      }      
     
   }   

   return latestCycleKroufrExtremeZoneReversal;       
}
/** End - CYCLE_KROUFR_VERSION Level, zones, slope and reversal*/

/** Start - QUANTILE_DSS Level and slope*/
/**
 * Retrieve the QUANTILE_DSS given buffer value and barIndex
 *
 * 0 = QUANTILE_DSS_SIGNAL, Never empty.
 * 5 = QUANTILE_DSS_UPPER, Never empty
 * 6 = QUANTILE_DSS_LOWER, Never empty
 */
double getQuantileDss(int length, int emaPeriod, int quanPeriod, int buffer, int barIndex) {

   return NormalizeDouble(iCustom(Symbol(), Period(), QUANTILE_DSS, length, emaPeriod, quanPeriod, buffer, barIndex), Digits);
}
Slope getQuantileDssSlope(int length, int emaPeriod, int quanPeriod, int barIndex) {

   double quantileDssSignalLevel= getQuantileDss(length, emaPeriod, quanPeriod, QUANTILE_DSS_SIGNAL, barIndex);
   double quantileDssUpperLevel = getQuantileDss(length, emaPeriod, quanPeriod, QUANTILE_DSS_UPPER, barIndex);
   double quantileDssLowerLevel = getQuantileDss(length, emaPeriod, quanPeriod, QUANTILE_DSS_LOWER, barIndex);
   
   if( quantileDssSignalLevel > quantileDssUpperLevel) {
      
      return BULLISH_SLOPE;
   }
   else if(quantileDssSignalLevel < quantileDssLowerLevel) {
      
      return BEARISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;
}
/** End - QUANTILE_DSS Level and slope*/

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

/** Start - EFT Level and slope*/
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
double getEftLevel(int length, int buffer, int barIndex) {
     
   int filterPeriod  = 1;           
   double weight     = 0.5;               
   //double filter     = 1;
   //int applyFilterTo = 2;   
   //return NormalizeDouble(iCustom(Symbol(), Period(), EFT, length, weight, filter, filterPeriod, applyFilterTo, buffer, barIndex), Digits);         
   return NormalizeDouble(iCustom(Symbol(), Period(), EFT, length, filterPeriod, weight, buffer, barIndex), Digits);
}
Slope getEftSlope(int length, int barIndex) {

   if(latestEftSlopeTime == getCurrentTime()) {
      
      return latestEftSlope;
   } 

           
   double slope = getEftLevel(length, EFT_SLOPE, barIndex);
   double signalLine = getEftLevel(length, EFT_SIGNAL, barIndex);
   double secondLine = getEftLevel(length, EFT_SECOND_LINE, barIndex);
   
   if( (latestEftSlope != BULLISH_SLOPE) && (slope == EMPTY_VALUE) && (signalLine > secondLine)) {
     
      latestEftSlope       = BULLISH_SLOPE;
      latestEftSlopeTime   = getCurrentTime();     
      return BULLISH_SLOPE;
   }
   else if( (latestEftSlope != BEARISH_SLOPE) && (slope != EMPTY_VALUE) && (signalLine < secondLine) ){
      
      latestEftSlope       = BEARISH_SLOPE;
      latestEftSlopeTime   = getCurrentTime();       
      return BEARISH_SLOPE;
   }

   return UNKNOWN_SLOPE;
}
/** End - EFT Level and slope*/

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
      
      Print("UPPER BANDS ARE FLAT at: " + (string)getCurrentTime());
   }
   else if(lowerPrev == lower) {
      
      Print("LOWER BANDS ARE FLAT at: " + (string)getCurrentTime());
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
      double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, previousBarIndex);      
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
         double dynamicMpaLevelCurr = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, barIndex);
         double dynamicMpaLevelPrev = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, previousBarIndex);
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

   if(latestT3OuterBandsReversalTime == getCurrentTime()) {
      
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
         latestT3OuterBandsReversalTime = getCurrentTime();         
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
         latestT3OuterBandsReversalTime = getCurrentTime();
         return BULLISH_REVERSAL;
      }      
   //}
   
   return CONTINUATION;          
}

/** START REVERSAL DETECTIONS */
Reversal getT3MiddleBandsReversal(bool checkCurrentBar) {

   if(latestT3MiddleBandsReversalTime == getCurrentTime()) {
      
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
         latestT3MiddleBandsReversalTime = getCurrentTime();
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
         latestT3MiddleBandsReversalTime = getCurrentTime();
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;
}

Reversal getDynamicPriceZonesAndJurikFilterReversal(int length) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBullishValuePrev  = getJurikFilterLevel(length, JURIK_FILTER_BULLISH_VALUE, CURRENT_BAR + 1);
      
      if( (jurikFilterBullishValuePrev > zoneLevelPrev)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, CURRENT_BAR + 1);
      
      //JURIK_FILTER
      double jurikFilterBearishValuePrev  = getJurikFilterLevel(length, JURIK_FILTER_BEARISH_VALUE, CURRENT_BAR + 1);
      
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
      double dynamicMpaUpperLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, barIndex);
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
            latestDynamicPriceZonesandJmaBandsReversalTime = getCurrentTime();            
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
            latestDynamicPriceZonesandJmaBandsReversalTime = getCurrentTime();             
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

   if(latestNonLinearKalmanSlopeTime == getCurrentTime()) {
      
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
         latestNonLinearKalmanSlopeTime = getCurrentTime();         
         return BEARISH_REVERSAL;
      }      
   //}
   //else if( trend == BEARISH_TREND ) {
      else if( (latestNonLinearKalmanSlope != BEARISH_SLOPE) // Ignore, already BEARISH_REVERSAL
             && (slopeCurr == BEARISH_SLOPE) && (slopePrev == BEARISH_SLOPE) ) {
         
         latestNonLinearKalmanSlope = BULLISH_SLOPE;
         latestNonLinearKalmanSlopeTime = getCurrentTime();
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
      double somatLevel = getSomat3Level(SOMAT3_MAIN, barIndex);
      //DIMPA
      double dynamicMpaUpperLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, barIndex);
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(length, DYNAMIC_MPA_SIGNAL, barIndex);
      
      if( (somatLevel > dynamicMpaUpperLevel) && (somatLevel > dynamicMpaSignalLevel) ) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_MAIN, barIndex);
      //DIMPA
      double dynamicMpaLowerLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_LOWER, barIndex);  
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(length, DYNAMIC_MPA_SIGNAL, barIndex);    
      
      if( (somatLevel < dynamicMpaLowerLevel) && (somatLevel < dynamicMpaSignalLevel) ) {
         
         return BULLISH_REVERSAL;
      }      
   }
   
   return CONTINUATION;      
}

//Diz = 5
//NON_LINEAR_KALMAN(20)/DYNAMIC_MPA(20)/(15)
//Change NON_LINEAR_KALMAN(20) color
//FROM the Top/Bottom Cross
//DYNAMIC_MPA_SIGNAL/DYNAMIC_MPA_MIDDLE CROSS

//Diz = 12
//TODO - Dont wait for the two to cross NON_LINEAR_KALMAN(20)/DYNAMIC_MPA(20). But, wait for NON_LINEAR_KALMAN(20) to change color on current and prev, then wait for DYNAMIC_MPA_SIGNAL/DYNAMIC_MPA_UPPER or
// DYNAMIC_MPA_SIGNAL/DYNAMIC_MPA_LOWER cross - 
//follow same pattern on verifying the cross just happened
Reversal getDynamicMpaAndNonLinearKalmanReversal(int dynamicMpaLength, int nonLinearKalmanLength, int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //NON_LINEAR_KALMAN
      double nonLinearKalmanLevel = getNonLinearKalmanLevel(nonLinearKalmanLength, NON_LINEAR_KALMAN_MAIN, barIndex);
      
      //DIMPA
      double dynamicMpaUpperLevel   = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, barIndex);
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
      
      /*if( (somatLevel > dynamicMpaUpperLevel) && (somatLevel > dynamicMpaSignalLevel) ) {
         
         return BEARISH_REVERSAL;
      }*/
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //NON_LINEAR_KALMAN
      double nonLinearKalmanLevel = getNonLinearKalmanLevel(nonLinearKalmanLength, NON_LINEAR_KALMAN_MAIN, barIndex);
      
      //DIMPA
      double dynamicMpaLowerLevel   = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, barIndex);  
      double dynamicMpaSignalLevel  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);    
      
      /*if( (somatLevel < dynamicMpaLowerLevel) && (somatLevel < dynamicMpaSignalLevel) ) {
         
         return BULLISH_REVERSAL;
      }*/      
   }
   
   return CONTINUATION;      
}

Reversal getSomat3Reversal(bool checkPreviousBarClose) {
  
   if(latestSomat3ReversalTime == getCurrentTime()) {
      return latestSomat3Reversal;
   } 
   
   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getSomat3Slope(CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getSomat3Slope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3Slope(barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getSomat3Slope(getPreviousBarIndex(CURRENT_BAR) );
      
      //Check if current and previous slopes changed direction      
      if(  (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            )  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if( (latestSomat3Reversal != BULLISH_REVERSAL) && (slopeCurr == BULLISH_SLOPE) ) {
            
            //Print("AT BULLISH");
            
            //Print("SLOPE is " + slopeCurr + " at " + getCurrentTime());
            //Print("SLOPE was " + slopeForOppositeDirectionVerification + " at " + latestSomat3ReversalTime);            
            
            latestSomat3Reversal = BULLISH_REVERSAL;
            latestSomat3ReversalTime = getCurrentTime();


            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_REVERSAL;
         }         
         else if( (latestSomat3Reversal != BEARISH_REVERSAL) && (slopeCurr == BEARISH_SLOPE) ) {
            
            //Print("AT BEARISH"); 

            //Print("SLOPE is " + slopeCurr + " at " + getCurrentTime());
            //Print("SLOPE was " + slopeForOppositeDirectionVerification + " at " + latestSomat3ReversalTime);             
            
            latestSomat3Reversal = BEARISH_REVERSAL;
            latestSomat3ReversalTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_REVERSAL;
         } 
         else {
            
            //Print("Here" + slopeCurr);
         }            
      }
      else {
         
         //Print("Here" + slopeCurr);
      }   
   }
   else {
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the getSomat3Slope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3Slope(barIndexForOppositeDirectionVerification);

      //Check if current and previous slopes changed direction      
      /*if( slopeForOppositeDirectionVerification != slopeCurr)  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {*/
         
         if(slopeCurr == BULLISH_SLOPE) {
         
            latestSomat3Reversal = BULLISH_REVERSAL;
            latestSomat3ReversalTime = getCurrentTime();  

            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_REVERSAL;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestSomat3Reversal = BEARISH_REVERSAL;
            latestSomat3ReversalTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_REVERSAL;
         }             
      //}      
      
   }

   return latestSomat3Reversal;       
}

Reversal getDynamicStepMaPdfReversal(int pdfMaLength, int pdfStepSize, bool checkPreviousBarClose) {
  
   if(latestDynamicStepMaPdfReversalTime == getCurrentTime()) {
      return latestDynamicStepMaPdfReversal;
   } 
   
   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getSomat3Slope(CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getDynamicStepMaPdfSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicStepMaPdfSlope(pdfMaLength, pdfStepSize, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicStepMaPdfSlope(pdfMaLength, pdfStepSize, getPreviousBarIndex(CURRENT_BAR) );
      
      //Check if current and previous slopes changed direction      
      if(  (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            )  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if( (latestDynamicStepMaPdfReversal != BULLISH_REVERSAL) && (slopeCurr == BULLISH_SLOPE) ) {
            
            //Print("AT BULLISH");
            
            //Print("SLOPE is " + slopeCurr + " at " + getCurrentTime());
            //Print("SLOPE was " + slopeForOppositeDirectionVerification + " at " + latestSomat3ReversalTime);            
            
            latestDynamicStepMaPdfReversal = BULLISH_REVERSAL;
            latestDynamicStepMaPdfReversalTime = getCurrentTime();


            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_REVERSAL;
         }         
         else if( (latestDynamicStepMaPdfReversal != BEARISH_REVERSAL) && (slopeCurr == BEARISH_SLOPE) ) {
            
            //Print("AT BEARISH"); 

            //Print("SLOPE is " + slopeCurr + " at " + getCurrentTime());
            //Print("SLOPE was " + slopeForOppositeDirectionVerification + " at " + latestSomat3ReversalTime);             
            
            latestDynamicStepMaPdfReversal = BEARISH_REVERSAL;
            latestDynamicStepMaPdfReversalTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_REVERSAL;
         } 
         else {
            
            //Print("Here" + slopeCurr);
         }            
      }
      else {
         
         //Print("Here" + slopeCurr);
      }   
   }
   else {
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the getDynamicStepMaPdfSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicStepMaPdfSlope(pdfMaLength, pdfStepSize, barIndexForOppositeDirectionVerification);

      //Check if current and previous slopes changed direction      
      /*if( slopeForOppositeDirectionVerification != slopeCurr)  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {*/
         
         if(slopeCurr == BULLISH_SLOPE) {
         
            latestDynamicStepMaPdfReversal = BULLISH_REVERSAL;
            latestDynamicStepMaPdfReversalTime = getCurrentTime();  

            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_REVERSAL;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestDynamicStepMaPdfReversal = BEARISH_REVERSAL;
            latestDynamicStepMaPdfReversalTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_REVERSAL;
         }             
      //}      
      
   }

   return latestDynamicStepMaPdfReversal;       
}

Reversal getDynamicPriceZonesAndSomat3Reversal(int barIndex) {

   if(latestDynamicPriceZonesAndSomat3ReversalTime == getCurrentTime()) {
      
      return latestDynamicPriceZonesAndSomat3Reversal;
   } 
   
   Slope slope = getSomat3Slope(barIndex);

   Trend trend = getDynamicPriceZonesTrend();
   if( trend == BULLISH_TREND ) {

      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_MAIN, barIndex);
      
      if( (somatLevel > zoneLevel) && (slope == BEARISH_SLOPE) ) { //Only if SOMAT3 is BULLISH extreme and suddenly changes to BEARISH_SLOPE 

         latestDynamicPriceZonesAndSomat3Reversal = BEARISH_REVERSAL;
         latestDynamicPriceZonesAndSomat3ReversalTime = getCurrentTime();           
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE 
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //SOMAT3
      double somatLevel = getSomat3Level(SOMAT3_MAIN, barIndex);
      
      if( (somatLevel < zoneLevel) && (slope == BULLISH_SLOPE)) { //Only if SOMAT3 is BEARISH extreme and suddenly changes to BULLISH_SLOPE  

         latestDynamicPriceZonesAndSomat3Reversal = BULLISH_REVERSAL;
         latestDynamicPriceZonesAndSomat3ReversalTime = getCurrentTime();          
         return BULLISH_REVERSAL;
      }      
   }
   
   return latestDynamicPriceZonesAndSomat3Reversal;      
}

Cross getSomat3AndKalmanBandsCross(int dynamicMpaLength, int nonLinearKalmanBandLength, bool checkPreviousBarClose, int barIndex) {

   /*if(latestDynamicMpaAndNonLinearKalmanBandsCrossTime == getCurrentTime()) {
      
      return latestDynamicMpaAndNonLinearKalmanBandsCross;
   } */

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndex);
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDSs) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, getPreviousBarIndex(CURRENT_BAR));

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
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDS) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
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
Slope getSomat3AndKalmanBandsSlope(int somat3Length, int kalmanBandLength, int barIndex) {

   Slope slope = getSomat3Slope(barIndex);
   double somat3Level = getSomat3Level(SOMAT3_MAIN, barIndex);
   if(slope == BULLISH_SLOPE) {
      
      double kalmanBandsLevel = getKalmanBandsLevel(kalmanBandLength,KALMAN_BAND_LOWER, barIndex);
      if(kalmanBandsLevel > somat3Level) {
      
         return BULLISH_SLOPE;
      }
      
   }
   else if(slope == BEARISH_SLOPE) {
   
      double kalmanBandsLevel = getKalmanBandsLevel(kalmanBandLength,KALMAN_BAND_UPPER, barIndex);

      if(kalmanBandsLevel < somat3Level) {
      
         return BEARISH_SLOPE;
      }      
   }

   return UNKNOWN_SLOPE;
}

Cross getSomat3AndSeBandsCross(int dynamicMpaLength, int nonLinearKalmanBandLength, bool checkPreviousBarClose, int barIndex) {

   /*if(latestDynamicMpaAndNonLinearKalmanBandsCrossTime == getCurrentTime()) {
      
      return latestDynamicMpaAndNonLinearKalmanBandsCross;
   } */

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndex);
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDSs) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, getPreviousBarIndex(CURRENT_BAR));

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
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDS) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
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
Slope getSomat3AndSeBandsSlope(int somat3Length, int seBandsLength, int barIndex) {

   Slope slope = getSomat3Slope(barIndex);
   double somat3Level = getSomat3Level(SOMAT3_MAIN, barIndex);
   double seBandsLevel = getSeBandsLevel(seBandsLength, SE_BAND_MAIN, barIndex);
   if(slope == BULLISH_SLOPE) {
      
      
      if(seBandsLevel > somat3Level) {
      
         return BULLISH_SLOPE;
      }
      
   }
   else if(slope == BEARISH_SLOPE) {
   
      if(seBandsLevel < somat3Level) {
      
         return BEARISH_SLOPE;
      }      
   }

   return UNKNOWN_SLOPE;
}

Cross getSomat3AndPolyfitBandsCross(int dynamicMpaLength, int nonLinearKalmanBandLength, bool checkPreviousBarClose, int barIndex) {

   /*if(latestDynamicMpaAndNonLinearKalmanBandsCrossTime == getCurrentTime()) {
      
      return latestDynamicMpaAndNonLinearKalmanBandsCross;
   } */

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndex);
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDSs) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, getPreviousBarIndex(CURRENT_BAR));

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
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDS) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
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
Slope getSomat3AndPolyfitBandsSlope(int somat3Length, int polyfitBandsLength, int barIndex) {

   Slope slope = getSomat3Slope(barIndex);
   double somat3Level = getSomat3Level(SOMAT3_MAIN, 0);
   
   if(slope == BULLISH_SLOPE) {
      
      double polyfitBandsLevel = getPolyfitBandsLevel(polyfitBandsLength, POLYFIT_BAND_SECOND_LOWER, 0);
      if(polyfitBandsLevel > somat3Level) {
      
         return BULLISH_SLOPE;
      }
      
   }
   else if(slope == BEARISH_SLOPE) {
   
      double polyfitBandsLevel = getPolyfitBandsLevel(polyfitBandsLength, POLYFIT_BAND_SECOND_UPPER, 0);
      if(polyfitBandsLevel < somat3Level) {
      
         return BEARISH_SLOPE;
      }      
   }

   return UNKNOWN_SLOPE;
}

Cross getDynamicMpaCross(int dynamicMpaLength, bool checkPreviousBarClose) {
  
   if(latestDynamicMpaCrossTime == getCurrentTime()) {
      
      return latestDynamicMpaCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaSlope(dynamicMpaLength, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the DIMPA was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaSlope(dynamicMpaLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaSlope(dynamicMpaLength, getPreviousBarIndex(CURRENT_BAR));

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            latestDynamicMpaCrossTime = getCurrentTime();  

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestDynamicMpaCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }
         else if(slopeCurr == NEW_BEARISH_SLOPE) { 
            
            latestDynamicMpaCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to NEW_BEARISH_SLOPE at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;         
         }
         else if(slopeCurr == NEW_BULLISH_SLOPE) { 
            
            latestDynamicMpaCrossTime = getCurrentTime(); 
            Print("CHANGING DIRECTION to NEW_BULLISH_SLOPE at " + convertCurrentTimeToString());                  
            return BULLISH_CROSS;         
         }         
         //latestDynamicMpaCross = BULLISH_CROSS;
               
         /*Print("CURRENT SLOPE " + slopeCurr + " @ " + convertCurrentTimeToString() );
         Print("PREV SLOPE " + slopePrev + " @ " + convertCurrentTimeToString() );
         Print("CHANGING DIRECTION at " + convertCurrentTimeToString()); */        
         
      }
      /*else if( ((slopeCurr == BEARISH_SLOPE) && (slopePrev == BEARISH_SLOPE) )// Current and previous slopes are BEARISH_SLOPE
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) )     // Last 2 bar index's should have been BULLISH_SLOPE to validate a BEARISH_CROSS
            {
      
         return BEARISH_CROSS;           
      } */    
   }
   else {//Check current - 2 Candles(Current and Prev) will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the DIMPA was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaSlope(dynamicMpaLength, barIndexForOppositeDirectionVerification);
      
      //Check if current slope changed direction      
      if(slopeCurr != slopeForOppositeDirectionVerification) {
         Print("slopeCurr " + (string)slopeCurr);
         Print("slopeForOppositeDirectionVerification " + (string)slopeForOppositeDirectionVerification);
         Print("CHANGING DIRECTION at " + convertCurrentTimeToString());
         latestDynamicMpaCross = BULLISH_CROSS;
         latestDynamicMpaCrossTime = getCurrentTime();         
         return BULLISH_CROSS;
      }
      /*else if( (slopeCurr == BEARISH_SLOPE) 
            && (slopeForOppositeDirectionVerification == BULLISH_SLOPE) ) 
            {
      
         return BEARISH_CROSS;           
      }*/              
   
   }

   return latestDynamicMpaCross;       
}
Slope getDynamicMpaSlope(int dynamicMpaLength, int barIndex) {

   double dynamicMpaSignal = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
   double dynamicMpaUpper  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, barIndex);    
   double dynamicMpaLower  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, barIndex); 
   double dynamicMpaMiddle = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_MIDDLE, barIndex);       

   if(dynamicMpaSignal > dynamicMpaUpper) {//Extreme Bullish - Above DYNAMIC_MPA_UPPER

      return BULLISH_SLOPE;
   } 
   else if(dynamicMpaSignal < dynamicMpaLower) { //Extreme Bearish - Below DYNAMIC_MPA_LOWER
   
      return BEARISH_SLOPE;
   }  
   else if( (dynamicMpaSignal < dynamicMpaUpper) && (dynamicMpaSignal > dynamicMpaLower)) { //New Bearish - Between DYNAMIC_MPA_LOWER and DYNAMIC_MPA_UPPER
   
      //Here we might have to check the Flat, or Slope?
      Flatter flatter = getDynamicMpaFlatter(dynamicMpaLength, false); //Check last closed bars - secured      
      if(flatter == BEARISH_FLATTER) {
         return NEW_BEARISH_SLOPE;
      }
      else if(flatter == BULLISH_FLATTER) {
         return NEW_BULLISH_SLOPE;
      }      
      
   }      
   
   return UNKNOWN_SLOPE;       
}

Cross getDynamicMpaAndNonLinearKalmanBandsCross(int dynamicMpaLength, int nonLinearKalmanBandLength, bool checkPreviousBarClose, int barIndex) {

   /*if(latestDynamicMpaAndNonLinearKalmanBandsCrossTime == getCurrentTime()) {
      
      return latestDynamicMpaAndNonLinearKalmanBandsCross;
   } */

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndex);
   
   if(checkPreviousBarClose) {
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDSs) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, getPreviousBarIndex(CURRENT_BAR));

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
      
      //To verify the pair(DIMPA and NON_LINEAR_KALMAN_BANDS) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndNonLinearKalmanBandsSlope(dynamicMpaLength, nonLinearKalmanBandLength, barIndexForOppositeDirectionVerification);
      
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
Slope getDynamicMpaAndNonLinearKalmanBandsSlope(int dynamicMpaLength, int nonLinearKalmanBandLength, int barIndex) {

   //DIMPA
   double dynamicMpaLevel = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);

   //NON_LINEAR_KALMAN_BANDS
   double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_MIDDLE, barIndex);     

   if(dynamicMpaLevel > nonLinearKalmanBandsLevel) {

      return BULLISH_SLOPE;
   }
   else if(dynamicMpaLevel < nonLinearKalmanBandsLevel) {
   
      return BEARISH_SLOPE;
   }

   return UNKNOWN_SLOPE;
}

Cross getDynamicMpaSignalLevelAndVolitilityBandsCross(int dynamicMpaLength, int volitilityLength, bool checkPreviousBarClose) {
  
   if(latestDynamicMpaSignalLevelAndVolitilityBandsCrossTime == getCurrentTime()) {
      return latestDynamicMpaSignalLevelAndVolitilityBandsCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaSignalLevelAndVolitilityBandsSlope(dynamicMpaLength, volitilityLength, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getDynamicMpaSignalLevelAndVolitilityBandsSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaSignalLevelAndVolitilityBandsSlope(dynamicMpaLength, volitilityLength, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaSignalLevelAndVolitilityBandsSlope(dynamicMpaLength, volitilityLength, getPreviousBarIndex(CURRENT_BAR) );

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            latestDynamicMpaSignalLevelAndVolitilityBandsCrossTime = getCurrentTime();  

            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestDynamicMpaSignalLevelAndVolitilityBandsCrossTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }             
      }   
   }

   return latestDynamicMpaSignalLevelAndVolitilityBandsCross;       
}
Slope getDynamicMpaSignalLevelAndVolitilityBandsSlope(int dynamicMpaLength, int volitilityLength, int barIndex) {

   //DIMPA
   double dynamicMpaSignal = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
   
   //VOLATILITY_BANDS
   double volitilityBandsLowerLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
   double volitilityBandsUpperLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);       

   if( (dynamicMpaSignal < volitilityBandsUpperLevel) && (dynamicMpaSignal < volitilityBandsLowerLevel) ) {//Extreme Bullish - Above DYNAMIC_MPA_UPPER

      return BULLISH_SLOPE;
   } 
   else if( (dynamicMpaSignal > volitilityBandsUpperLevel) && (dynamicMpaSignal > volitilityBandsLowerLevel) ) { //Extreme Bearish - Below DYNAMIC_MPA_LOWER
   
      return BEARISH_SLOPE;
   }
   
   return UNKNOWN_SLOPE;       
}

Cross getDynamicMpaAndVolitilityBandsCross(int dynamicMpaLength, int volitilityLength, bool checkPreviousBarClose, bool checkBothVolitilityBands) {
  
   if(latestDynamicMpaAndVolitilityBandsCrossTime == getCurrentTime()) {
      return latestDynamicMpaAndVolitilityBandsCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getDynamicMpaAndVolitilityBandsSlope(dynamicMpaLength, volitilityLength, checkBothVolitilityBands, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getDynamicMpaAndVolitilityBandsSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getDynamicMpaAndVolitilityBandsSlope(dynamicMpaLength, volitilityLength, checkBothVolitilityBands, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getDynamicMpaAndVolitilityBandsSlope(dynamicMpaLength, volitilityLength, checkBothVolitilityBands, getPreviousBarIndex(CURRENT_BAR) );

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            latestDynamicMpaAndVolitilityBandsCrossTime = getCurrentTime();  

            //Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestDynamicMpaAndVolitilityBandsCrossTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }
         else if(slopeCurr == NEW_BEARISH_SLOPE) { 
            
            latestDynamicMpaCrossTime = getCurrentTime(); 
            
            //Print("CHANGING DIRECTION to NEW_BEARISH_SLOPE at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;         
         }
         else if(slopeCurr == NEW_BULLISH_SLOPE) { 
            
            latestDynamicMpaCrossTime = getCurrentTime(); 
            //Print("CHANGING DIRECTION to NEW_BULLISH_SLOPE at " + convertCurrentTimeToString());                  
            return BULLISH_CROSS;         
         }                       
      }   
   }

   return latestDynamicMpaAndVolitilityBandsCross;        
}
Slope getDynamicMpaAndVolitilityBandsSlope(int dynamicMpaLength, int volitilityLength, bool checkBothVolitilityBands, int barIndex) {

   //DIMPA
   double dynamicMpaSignal = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
   double dynamicMpaUpper  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, barIndex);
   double dynamicMpaLower  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, barIndex);
   double dynamicMpaMiddle = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_MIDDLE, barIndex);
   
   //VOLATILITY_BANDS
   double volitilityBandsLowerLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
   double volitilityBandsUpperLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);       

   if(checkBothVolitilityBands) {
      if( (dynamicMpaUpper < volitilityBandsUpperLevel) && (dynamicMpaUpper < volitilityBandsLowerLevel) ) {//Extreme Bullish - Both VOLATILITY_BANDS above DYNAMIC_MPA_UPPER
   
         return BULLISH_SLOPE;
      } 
      else if( (dynamicMpaLower > volitilityBandsUpperLevel) && (dynamicMpaLower > volitilityBandsLowerLevel) ) { //Extreme Bearish - Both VOLATILITY_BANDS below DYNAMIC_MPA_LOWER
      
         return BEARISH_SLOPE;
      }//Straight Bullish/Bearish test above
   }
   else { //Only check DYNAMIC_MPA_UPPER - BULLISH, or DYNAMIC_MPA_LOWER - BEARISH
      
         if( dynamicMpaUpper < volitilityBandsUpperLevel) {//Bullish - DYNAMIC_MPA_UPPER above DYNAMIC_MPA_UPPER
      
            return BULLISH_SLOPE;
         } 
         else if( dynamicMpaLower > volitilityBandsLowerLevel) { //Bearish - VOLATILITY_BAND_UPPER below DYNAMIC_MPA_LOWER
            
            return BEARISH_SLOPE;
         } 
         //VOLATILITY_BANDs roaming between DYNAMIC_MPA_LOWER and DYNAMIC_MPA_UPPER - NO USE FOR NOW - 04/08/2018
         else if( (volitilityBandsUpperLevel < dynamicMpaUpper) && (volitilityBandsLowerLevel > dynamicMpaLower)) { //ALL VOLATILITY_BANDs Between DYNAMIC_MPA_LOWER and DYNAMIC_MPA_UPPER
         
            //Here we might have to check the Flat, or Slope?
            Flatter flatter = getDynamicMpaFlatter(dynamicMpaLength, false); //false = Check last closed bars - secured      
            if(flatter == BEARISH_FLATTER) {
               return NEW_BEARISH_SLOPE;
            }
            else if(flatter == BULLISH_FLATTER) {
               return NEW_BULLISH_SLOPE;
            }      
            
         }               
   }
   
 
   
   return UNKNOWN_SLOPE;       
}
Slope getDynamicMpaAndVolitilityBandsConsolidationSlope(int dynamicMpaLength, int volitilityLength, int barIndex) {

   //DIMPA
   double dynamicMpaSignal = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_SIGNAL, barIndex);
   double dynamicMpaUpper  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, barIndex);
   double dynamicMpaLower  = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, barIndex);
   double dynamicMpaMiddle = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_MIDDLE, barIndex);
   
   //VOLATILITY_BANDS
   double volitilityBandsLowerLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_LOWER, barIndex);
   double volitilityBandsUpperLevel = getVolitilityBandsLevel(volitilityLength, VOLATILITY_BAND_UPPER, barIndex);       

   //Consolidation State
   if( (dynamicMpaUpper < volitilityBandsUpperLevel) && (dynamicMpaUpper > volitilityBandsLowerLevel) ) { // DYNAMIC_MPA_UPPER is between the VOLATILITY_BAND - Consolidation
      
      return BULLISH_CONSOLIDATION_SLOPE;
   }
   else if( (dynamicMpaLower > volitilityBandsLowerLevel) && (dynamicMpaLower < volitilityBandsUpperLevel) ) { // DYNAMIC_MPA_LOWER is between the VOLATILITY_BAND - Consolidation
      
      return BEARISH_CONSOLIDATION_SLOPE;
   }

   return UNKNOWN_SLOPE;       
}

/** 
 * Only check if previous volitilityBandsLevel was outside dynamicMpaLevel and is now inside. 
 * When this happens, the dynamicMpaLevel should atleast have been flat for current and previous level, getDynamicMpaFlatter(true)
 */
Transition getDynamicMpaAndVolitilityBandsReversal(int dynamicMpaLength, int volitilityLength, bool checkCurrentBar, bool checkPreviousVolitilityBandsLevels) {

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
      double dynamicMpaLevelCurr = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, previousBarIndex);      
      
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
      double dynamicMpaLevelCurr = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, barIndex);
      double dynamicMpaLevelPrev = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, previousBarIndex);
      
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
         double dynamicMpaLevelCurr = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, barIndex);
         double dynamicMpaLevelPrev = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_UPPER, previousBarIndex);
         
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
         dynamicMpaLevelCurr = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, barIndex);
         dynamicMpaLevelPrev = getDynamicMpaLevel(dynamicMpaLength, DYNAMIC_MPA_LOWER, previousBarIndex);
         
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


Cross getRsiomaBandsCross(int length, bool checkPreviousBarClose) {
  
   if(latestRsiomaBandsCrossTime == getCurrentTime()) {
      return latestRsiomaBandsCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getRsiomaBandsSlope(length, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getRsiomaBandsSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getRsiomaBandsSlope(length, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getRsiomaBandsSlope(length, getPreviousBarIndex(CURRENT_BAR) );

      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            latestRsiomaBandsCrossTime = getCurrentTime();  

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestRsiomaBandsCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }             
      }   
   }

   return latestRsiomaBandsCross;       
}

Cross getEftCross(int length, bool checkPreviousBarClose) {
  
   if(latestEftCrossTime == getCurrentTime()) {
      return latestEftCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getEftSlope(length, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getEftSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getEftSlope(length, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getEftSlope(length, getPreviousBarIndex(CURRENT_BAR) );
      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            
            latestEftCrossTime = getCurrentTime();  

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestEftCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }             
      }   
   }
   else {
      
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the getEftSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getEftSlope(length, barIndexForOppositeDirectionVerification);
              
      if( slopeForOppositeDirectionVerification != slopeCurr ) {

         if(slopeCurr == BULLISH_SLOPE) {
            
            latestEftCrossTime = getCurrentTime();  

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestEftCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }             
      }   
   }   

   return latestQuantileDssCross;       
}


Cross getQuantileDssCross(int length, int emaPeriod, int quanPeriod, bool checkPreviousBarClose, int barIndex) {
  
   if(latestQuantileDssCrossTime == getCurrentTime()) {
      return latestQuantileDssCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getQuantileDssSlope(length, emaPeriod, quanPeriod, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the getQuantileDssSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getQuantileDssSlope(length, emaPeriod, quanPeriod, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getQuantileDssSlope(length, emaPeriod, quanPeriod, getPreviousBarIndex(CURRENT_BAR) );
      //Check if current and previous slopes changed direction      
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            latestQuantileDssCrossTime = getCurrentTime();  

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestQuantileDssCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }             
      }   
   }
   else {
      
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the getQuantileDssSlope was heading to the opposite direction
      slopeForOppositeDirectionVerification = getQuantileDssSlope(length, emaPeriod, quanPeriod, barIndexForOppositeDirectionVerification);
           
      if( slopeForOppositeDirectionVerification != slopeCurr ) {
         
         if(slopeCurr == BULLISH_SLOPE) {
            latestQuantileDssCrossTime = getCurrentTime();  

            Print("CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestQuantileDssCrossTime = getCurrentTime(); 
            
            Print("CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }             
      }   
   }   

   return latestQuantileDssCross;       
}

/**
 * All crosses must be verified - The pair(SOMAT3 and NON_LINEAR_KALMAN) must have been heading to the opposite direction of the cross before the cross happens.
 */
Cross getSomat3AndNonLinearKalmanCross(int nonLinearKalmanLength,  bool checkNonLinearKalmanSlope, bool checkPreviousBarClose) {

   Print("In getSomat3AndNonLinearKalmanCross");
   if(latestSomat3AndNonLinearKalmanCrossTime == getCurrentTime()) {
      return latestSomat3AndNonLinearKalmanCross;
   } 

   int barIndexForOppositeDirectionVerification = -1;
   Slope slopeForOppositeDirectionVerification  = UNKNOWN_SLOPE;
   Slope slopeCurr = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, CURRENT_BAR);
   
   if(checkPreviousBarClose) {//Check previous(Current, Prev, Prev + 1) - 3 Candles will be involved
      
      barIndexForOppositeDirectionVerification = getPastBars(2);
      
      //To verify the pair(SOMAT3 and NON_LINEAR_KALMAN) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, barIndexForOppositeDirectionVerification);
      
      //Previous slope
      Slope slopePrev = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, getPreviousBarIndex(CURRENT_BAR));

      //Check if current and previous slopes changed direction           
      if( ( (slopeCurr == slopePrev) // Current and previous slopes are BULLISH_SLOPE
            && (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 2 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
         if(slopeCurr == BULLISH_SLOPE) {
            
            latestSomat3AndNonLinearKalmanCross = BULLISH_CROSS; 
            latestSomat3AndNonLinearKalmanCrossTime = getCurrentTime(); 
             

            Print("PREV BAR: CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
            return BULLISH_CROSS;
         }         
         else if(slopeCurr == BEARISH_SLOPE) {
            
            latestSomat3AndNonLinearKalmanCross = BEARISH_CROSS; 
            latestSomat3AndNonLinearKalmanCrossTime = getCurrentTime(); 
            
            Print("PREV BAR: CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
            return BEARISH_CROSS;
         }                            
      }     
   }
   else {
   
      barIndexForOppositeDirectionVerification = getPastBars(1);
      
      //To verify the pair(SOMAT3 and NON_LINEAR_KALMAN) was heading to the opposite direction
      slopeForOppositeDirectionVerification = getSomat3AndNonLinearKalmanSlope(nonLinearKalmanLength, checkNonLinearKalmanSlope, barIndexForOppositeDirectionVerification);
      
      //Check if current slope changed direction      
      if( ( (slopeForOppositeDirectionVerification != slopeCurr) ))  // Last 1 bar index's should have been BEARISH_SLOPE to validate a BULLISH_CROSS
            {
         
            if(slopeCurr == BULLISH_SLOPE) {
               
               latestSomat3AndNonLinearKalmanCross = BULLISH_CROSS; 
               latestSomat3AndNonLinearKalmanCrossTime = getCurrentTime(); 
   
               Print("CURRENT BAR: CHANGING DIRECTION BULLISH_CROSS at " + convertCurrentTimeToString());                 
               return BULLISH_CROSS;
            }         
            else if(slopeCurr == BEARISH_SLOPE) {
               
               latestSomat3AndNonLinearKalmanCross = BEARISH_CROSS; 
               latestSomat3AndNonLinearKalmanCrossTime = getCurrentTime(); 
               
               Print("CURRENT BAR: CHANGING DIRECTION to BEARISH_CROSS at " + convertCurrentTimeToString());                  
               return BEARISH_CROSS;
            }                       
      }              
   
   }

   return UNKNOWN_CROSS;      
}
Slope getSomat3AndNonLinearKalmanSlope(int nonLinearKalmanLength, bool checkNonLinearKalmanSlope, int barIndex) {

   double somat3Level  = getSomat3Level(SOMAT3_MAIN, barIndex);
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

Slope getSomat3AndHullMaSlope(int hullMaLength, bool checkHullMaSlope, int barIndex) {

   double somat3Level  = getSomat3Level(SOMAT3_MAIN, barIndex);
   double hullMaLevel  = getHullMaLevel(hullMaLength, HULL_MA_MAIN_VALUE, barIndex);  

   if(somat3Level < hullMaLevel) {

      if(checkHullMaSlope) { // More strict if checkHullMaSlope==true
         
         return getHullMaSlope(hullMaLength, barIndex);
      }
      else {
         
         return BULLISH_SLOPE;
      }   
   }
   else if(somat3Level > hullMaLevel) {
   
      if(checkHullMaSlope) { // More strict if checkHullMaSlope==true
         
         return getHullMaSlope(hullMaLength, barIndex);
      }
      else {
         
         return BEARISH_SLOPE;
      }
   }

   return UNKNOWN_SLOPE;      
}

Slope getSomat3AndJurikFilterSlope(int jurikFilterLength, bool checkJurikFilterSlope, int barIndex) {

   double somat3Level  = getSomat3Level(SOMAT3_MAIN, barIndex);
   double jurikFilterLevel  = getJurikFilterLevel(jurikFilterLength, JURIK_FILTER_MAIN_VALUE, barIndex);  

   if(somat3Level < jurikFilterLevel) {

      if(checkJurikFilterSlope) { // More strict if checkJurikFilterSlope==true
         
         return getJurikFilterSlope(jurikFilterLength, barIndex);
      }
      else {
         
         return BULLISH_SLOPE;
      }   
   }
   else if(somat3Level > jurikFilterLevel) {
   
      if(checkJurikFilterSlope) { // More strict if checkJurikFilterSlope==true
         
         return getJurikFilterSlope(jurikFilterLength, barIndex);
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

   double somat3Level  = getSomat3Level(SOMAT3_MAIN, barIndex);
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

Reversal getDynamicPriceZonesAndNonLinearKalmanBandsReversal(int nonLinearKalmanBandLength) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, CURRENT_BAR + 1);
      
      //NON_LINEAR_KALMAN_BANDS
      double nonLinearKalmanBandsLevel = getNonLinearKalmanBandsLevel(nonLinearKalmanBandLength, NON_LINEAR_KALMAN_BANDS_UPPER, CURRENT_BAR + 1);
      
      if( ( ( latestNonLinearKalmanBandsReversal != BEARISH_REVERSAL) && (nonLinearKalmanBandsLevel > zoneLevelPrev) ) ) {
         
         latestNonLinearKalmanBandsReversalTime = getCurrentTime();
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
         
         latestNonLinearKalmanBandsReversalTime = getCurrentTime();
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

Reversal getDynamicPriceZonesAndHullMaReversal(int length, int barIndex) {

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      
      //HULL_MA
      double maLevel = getHullMaLevel(length, HULL_MA_MAIN_VALUE, barIndex);
      
      if( (maLevel > zoneLevel)) {
         
         return BEARISH_REVERSAL;
      }
      
   }
   else if( trend == BEARISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevel  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_LOWER_LEVEL, barIndex);
      
      //HULL_MA
      double maLevel = getHullMaLevel(length, HULL_MA_MAIN_VALUE, barIndex);
      
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

/** START STRATEGIES */
Signal getDynamicPriceZonesAndDynamicMpaAndVolitilityBandsSignal(int length, int barIndex) { 

   Trend trend = getDynamicPriceZonesTrend();   
   if( trend == BULLISH_TREND ) {
      
      //DYNAMIC_PRICE_ZONE
      double zoneLevelPrev  = getDynamicPriceZonesLevel(DYNAMIC_PRICE_ZONE_UPPER_LEVEL, barIndex);
      //DYNAMIC_MPA
      double dynamicMpaLevel   = getDynamicMpaLevel(length, DYNAMIC_MPA_UPPER, barIndex);
      
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

   Reversal rev = getDynamicPriceZonesAndJurikFilterReversal(15);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}


void getDynamicPriceZonesAndLinearMaReversalTest() {

   Reversal rev = getDynamicPriceZonesAndLinearMaReversal(CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getDynamicPriceZonesAndHullMaReversalTest() {

   Reversal rev = getDynamicPriceZonesAndHullMaReversal(18, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getDynamicMpaReversalTest() {

   Flatter flatter = getDynamicMpaFlatter(20, false);
   
   if(flatter == BEARISH_FLATTER) {
   
      if(latestDynamicMpaFlatterTime == getCurrentTime()) {
         Print("BEARISH FLATTER at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(flatter == BULLISH_FLATTER) {
      //Print("BULLISH_FLATTER");
      if(latestDynamicMpaFlatterTime == getCurrentTime()) {
         Print("BULLISH FLATTER at: " + convertCurrentTimeToString());
      } 
   }     
}

void getDynamicOfAveragesReversalTest() {

   Flatter flatter = getDynamicOfAveragesFlatter(20, false);
   
   if(flatter == BEARISH_FLATTER) {
   
      if(latestDynamicOfAveragesFlatter != BEARISH_FLATTER) {
         
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }          
   }
   else if(flatter == BULLISH_FLATTER) {
      
      if( latestDynamicOfAveragesFlatter != BULLISH_FLATTER ) {      

         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }  
}

void getMainStochReversalTest() {

   Reversal rev = getMainStochReversal(false);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }  
}

void getDimpaAndSomat3ReversalTest() {

   Reversal rev = getDynamicMpaAndSomat3Reversal(20, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getDynamicPriceZonesAndVolitilityBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesAndVolitilityBandsReversal(20, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getDynamicPriceZonesAndMlsBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesAndMlsBandsReversal(CURRENT_BAR + 1);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestMlsBandsSignalTime != getCurrentTime()) {
         
         latestMlsBandsSignal = SELL_SIGNAL;
         latestMlsBandsSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestMlsBandsSignalTime != getCurrentTime() ) {      
         
         latestMlsBandsSignal = BUY_SIGNAL;
         latestMlsBandsSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getDynamicPriceZonesAndSrBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesAndSrBandsReversal(CURRENT_BAR + 1);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSrBandsSignalTime != getCurrentTime()) {
         
         latestSrBandsSignal = SELL_SIGNAL;
         latestSrBandsSignalTime = getCurrentTime();
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSrBandsSignalTime != getCurrentTime() ) {      
         
         latestSrBandsSignal = BUY_SIGNAL;
         latestSrBandsSignalTime = getCurrentTime();
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getDonchianChannelOverlapTest() {

   getDonchianChannelOverlap();
}

void getJurikFilterSlopeTest(){ 

   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   Slope slope = getJurikFilterSlope(15, CURRENT_BAR + 1);
   
   if( (slope == BULLISH_SLOPE) && (latestJurikSlope != BULLISH_SLOPE) ) {
      
      latestJurikSlope = BULLISH_SLOPE;
      Print("BULLISH SLOPE " + convertCurrentTimeToString());
   }
   else if( (slope == BEARISH_SLOPE) && (latestJurikSlope != BEARISH_SLOPE)) {
      
      latestJurikSlope = BEARISH_SLOPE;
      Print("BEARISH SLOPE " + convertCurrentTimeToString());
   }
}

void getHullMaSlopeTest(){ 

   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   Slope slope = getHullMaSlope(18, CURRENT_BAR + 1);
   
   if( (slope == BULLISH_SLOPE) && (latestHmaSlope != BULLISH_SLOPE) ) {
      
      latestHmaSlope = BULLISH_SLOPE;
      //Print("BULLISH SLOPE " + convertCurrentTimeToString());
   }
   else if( (slope == BEARISH_SLOPE) && (latestHmaSlope != BEARISH_SLOPE)) {
      
      latestHmaSlope = BEARISH_SLOPE;
      //Print("BEARISH SLOPE " + convertCurrentTimeToString());
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
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getT3CrossSignalTest() {

   Signal signal = getT3CrossSignal(true);
   
   if(signal == BUY_SIGNAL) {
         Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(signal == SELL_SIGNAL) {
      Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getJmaBandsLevelCrossReversalTest() {

   Reversal rev = getJmaBandsLevelCrossReversal();
   
   if(rev == BEARISH_REVERSAL) {
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }  
}

void getDynamicPriceZonesandJmaBandsReversalTest() {

   Reversal rev = getDynamicPriceZonesandJmaBandsReversal(CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
         Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
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
      Print("In a BULLISH_SHORT_TERM_TREND MODE at " + convertCurrentTimeToString() );
   }
   else if(trend == BEARISH_SHORT_TERM_TREND) {
      Print("In a BEARISH_SHORT_TERM_TREND MODE at " + convertCurrentTimeToString() );
   }  
}

//This is concrete - Uses previous close of VolitilityBands. A bit late - needs to be optimised
void getDynamicMpaAndVolitilityBandsReversalTest() {

   if(latestTransitionTime != getCurrentTime()) { //Allow only 1 signal per candle
     
      Transition transition = getDynamicMpaAndVolitilityBandsReversal(20, 20, false, true);
      
      if(transition == BULLISH_TO_BEARISH_TRANSITION) {
      
         if(latestTransition != BULLISH_TO_BEARISH_TRANSITION) {
            
            latestTransitionTime = getCurrentTime();
            latestTransition = BULLISH_TO_BEARISH_TRANSITION;
            Print("BULLISH_TO_BEARISH_TRANSITION at: " + convertCurrentTimeToString());
         }          
      }
      else if(transition == BEARISH_TO_BULLISH_TRANSITION) {
         
         if( latestTransition != BEARISH_TO_BULLISH_TRANSITION ) {      
            
            latestTransitionTime = getCurrentTime();
            latestTransition = BEARISH_TO_BULLISH_TRANSITION;
            Print("BEARISH_TO_BULLISH_TRANSITION at: " + convertCurrentTimeToString());
         }
      }
      else if(transition == SUDDEN_BULLISH_TO_BEARISH_TRANSITION) {
         if( latestTransition != SUDDEN_BULLISH_TO_BEARISH_TRANSITION ) {      
            
            latestTransitionTime = getCurrentTime();
            latestTransition = SUDDEN_BULLISH_TO_BEARISH_TRANSITION;
            Print("SUDDEN_BULLISH_TO_BEARISH_TRANSITION at: " + convertCurrentTimeToString());
         }   
      }
      else if(transition == SUDDEN_BEARISH_TO_BULLISH_TRANSITION) {
         if( latestTransition != SUDDEN_BEARISH_TO_BULLISH_TRANSITION ) {      
            
            latestTransitionTime = getCurrentTime();
            latestTransition = SUDDEN_BEARISH_TO_BULLISH_TRANSITION;
            Print("SUDDEN_BEARISH_TO_BULLISH_TRANSITION at: " + convertCurrentTimeToString());
         }   
      }
   }   
}

void getDynamicPriceZonesAndNonLinearKalmanBandsReversalTest() {

   //Use 15 for getDynamicPriceZonesAndNonLinearKalmanBandsReversal and 20 Dimpa getDynamicMpaAndNonLinearKalmanBandsCross
   Reversal rev = getDynamicPriceZonesAndNonLinearKalmanBandsReversal(15); 
   
   if(rev == BEARISH_REVERSAL) {   
      Print("BEARISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(rev == BULLISH_REVERSAL) {
      Print("BULLISH REVERSAL SIGNAL at: " + convertCurrentTimeToString());
   }   
}


//LATEST TESTS
void getDynamicMpaAndNonLinearKalmanBandsCrossTest() {

   //Use 15 for getDynamicPriceZonesAndNonLinearKalmanBandsReversal and 20 Dimpa getDynamicMpaAndNonLinearKalmanBandsCross
   Cross cross = getDynamicMpaAndNonLinearKalmanBandsCross(20, 20, true, CURRENT_BAR + 1); 
   
   if(cross == BEARISH_CROSS) {
   
      if(latestDynamicMpaAndNonLinearKalmanBandsCross != BEARISH_CROSS) {
         
         Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(cross == BULLISH_CROSS) {
      
      if( latestDynamicMpaAndNonLinearKalmanBandsCross != BULLISH_CROSS ) {      
         
         Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}

void getSomat3AndNonLinearKalmanCrossTest() {

   if(latestSomat3AndNonLinearKalmanCrossTime == getCurrentTime()) {
      
      return;
   }

   Cross cross = getSomat3AndNonLinearKalmanCross(20, true, true); 
   
   if(cross == BEARISH_CROSS) {
   
      if(latestDynamicMpaAndNonLinearKalmanBandsCross != BEARISH_CROSS) {
         
         Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
      }    
      
   }
   else if(cross == BULLISH_CROSS) {
      
      if( latestDynamicMpaAndNonLinearKalmanBandsCross != BULLISH_CROSS ) {      
         
         Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
      }
   }   
}


void getDynamicMpaAndNonLinearKalmanBandsSlopeTest() {

   Slope slope = getDynamicMpaAndNonLinearKalmanBandsSlope(20, 20, CURRENT_BAR+1);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getSomat3AndNonLinearKalmanSlopeTest() {

   Slope slope = getSomat3AndNonLinearKalmanSlope(20, true, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getNonLinearKalmanAndVolitilityBandsSlopeTest() {

   Slope slope = getNonLinearKalmanAndVolitilityBandsSlope(20, 20, true, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getSomat3AndVolitilityBandsSlopeTest() {

   Slope slope = getSomat3AndVolitilityBandsSlope(20, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getDynamicMpaAndSlopeTest() {

   Slope slope = getDynamicMpaSlope(20, CURRENT_BAR + 1);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getDynamicMpaCrossTest() {

   Cross cross = getDynamicMpaCross(20, true);
   
   if(cross == BEARISH_CROSS) {   
      //Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(cross == BULLISH_CROSS) {
      //Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }   
}



void getDynamicMpaSignalLevelAndVolitilityBandsSlopeTest() {

   Slope slope = getDynamicMpaSignalLevelAndVolitilityBandsSlope(20, 20, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }    
}

void getDynamicMpaAndVolitilityBandsSlopeTest() {

   Slope slope = getDynamicMpaAndVolitilityBandsSlope(15, 20, false, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }    
}

void getDynamicMpaSignalLevelAndVolitilityBandsCrossTest() {

   Cross cross = getDynamicMpaSignalLevelAndVolitilityBandsCross(20, 20, true);
   
   if(cross == BEARISH_CROSS) {   
      Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(cross == BULLISH_CROSS) {
      Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getDynamicMpaAndVolitilityBandsCrossTest() {

   Cross cross = getDynamicMpaAndVolitilityBandsCross(15, 20, true, false);
   
   if(cross == BEARISH_CROSS) {   
      Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(cross == BULLISH_CROSS) {
      Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }   
}

int getDynamicMpaAndVolitilityBandsCombinedCrossTest() {

   if(dynamicMpaAndVolitilityBandsCombinedCrossTime == getCurrentTime()) {
      
      return -1;;
   }
   
   Reversal rev = getDynamicMpaAndSomat3Reversal(20, CURRENT_BAR);
   
   if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         
         return OP_SELL;
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         
         return OP_BUY;
      }
   }  

      
      
   
   
   /*
   Cross dynamicMpaAndVolitilityBandsCross      = getDynamicMpaAndVolitilityBandsCross(15, 20, true, false);
   Cross mpaSignalLevelAndVolitilityBandsCross  = getDynamicMpaSignalLevelAndVolitilityBandsCross(20, 20, true);
      
   if( (dynamicMpaAndVolitilityBandsCombinedCross != BEARISH_CROSS) && ((dynamicMpaAndVolitilityBandsCross == BEARISH_CROSS) || (mpaSignalLevelAndVolitilityBandsCross == BEARISH_CROSS)) ) {   
      
      dynamicMpaAndVolitilityBandsCombinedCross = BEARISH_CROSS;
      dynamicMpaAndVolitilityBandsCombinedCrossTime = getCurrentTime();
      
      //Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
      return OP_SELL;
   }
   else if( (dynamicMpaAndVolitilityBandsCombinedCross != BULLISH_CROSS) && ((dynamicMpaAndVolitilityBandsCross == BULLISH_CROSS) || (mpaSignalLevelAndVolitilityBandsCross == BULLISH_CROSS)) ) {
      
      dynamicMpaAndVolitilityBandsCombinedCross = BULLISH_CROSS;
      dynamicMpaAndVolitilityBandsCombinedCrossTime = getCurrentTime();
      //Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
      return OP_BUY;
   }*/
   
   return -1;   
}





/*
TODO - 04/08/2018:
1. ADD TEST FOR getDynamicMpaAndVolitilityBandsCross. 
2. Replace getDynamicMpaAndVolitilityBandsReversal implementation with getDynamicMpaAndVolitilityBandsSlope implementation(new method)
3. Combine/ Compare getDynamicMpaSignalLevelAndVolitilityBandsCrossTest(getDynamicMpaSignalLevelAndVolitilityBandsCross) and getDynamicMpaAndVolitilityBandsSlopeTest(getDynamicMpaAndVolitilityBandsSlope)

*/

//SOMAT Crosses
// - Jurik(10), HMA(15), NonLinear Kalman(20)
//TODO


void getRsiomaBandsSlopeTest() {

   Slope slope = getRsiomaBandsSlope(20, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }    
}

void getRsiomaBandsCrossTest() {

   Cross cross = getRsiomaBandsCross(30, true);
   
   if(cross == BEARISH_CROSS) {   
      //Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(cross == BULLISH_CROSS) {
      //Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }   
}

void getQuantileDssSlopeTest() {

   Slope slope = getQuantileDssSlope(10, 12, 5, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }    
}

void getQuantileDssCrosstTest() {

   Cross cross = getQuantileDssCross(10, 12, 5, true, CURRENT_BAR);
   
   if(cross == BEARISH_CROSS) {   
      //Print("BEARISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(cross == BULLISH_CROSS) {
      //Print("BULLISH CROSS SIGNAL at: " + convertCurrentTimeToString());
   }   
}

int StrategyTester() {

   //Reversal rev = getSomat3Reversal(true);
   Cross cross = getSomat3AndNonLinearKalmanCross(20, true, true);
   
   if(cross == BEARISH_CROSS) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         
         return OP_SELL;
      }    
      
   }
   else if(cross == BULLISH_CROSS) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         
         return OP_BUY;
      }
   }   

   /*if(rev == BEARISH_REVERSAL) {
   
      if(latestSignal != SELL_SIGNAL) {
         
         latestSignal = SELL_SIGNAL;
         latestSignalTime = getCurrentTime();
         
         return OP_SELL;
      }    
      
   }
   else if(rev == BULLISH_REVERSAL) {
      
      if( latestSignal != BUY_SIGNAL ) {      
         
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();
         
         return OP_BUY;
      }
   }*/  
   
   return -1; 
}

void getSomat3SlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
   int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);   
   
   double slope = getSomat3Slope(2); //For some reason the previous bar is 2 not 1, Same as STEPPED_TTA?

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);  
      
      Print("==========================================");  
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         Print("Fake signal at " + (string)getCurrentTime());
      }
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);        
      
      Print("==========================================");
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         Print("Fake signal at " + (string)getCurrentTime());
      }      
      
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getDynamicStepMaPdfSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
   int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);   
   
   Slope slope = getDynamicStepMaPdfSlope(10, 15, 2); //For some reason the previous bar is 2 not 1, Same as STEPPED_TTA?

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);  
      
      Print("==========================================");  
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         //Print("Fake signal at " + (string)getCurrentTime());
      }
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);        
      
      Print("==========================================");
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         //Print("Fake signal at " + (string)getCurrentTime());
      }      
      
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getDynamicStepMaPdfCrossTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   Cross cross = getDynamicStepMaPdfCross(10, 5, 10, CURRENT_BAR);

   if(latestSignal != BUY_SIGNAL && cross == BULLISH_CROSS) {
      
      Print("==========================================");  
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && cross == BEARISH_CROSS) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);

      Print("==========================================");
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getSteppedTtaSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
      int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
      int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);   
   
   Slope slope = getSteppedTtaSlope(5, 1, 1); //For some reason the previous bar is 2 not 1, Same as SOMAT3?

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);  
      
      Print("==========================================");  
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         //Print("Fake signal at " + (string)getCurrentTime());
      }
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);        
      
      Print("==========================================");
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         //Print("Fake signal at " + (string)getCurrentTime());
      }      
      
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getSuperTrendSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
      int latestDynamicOfAveragesReversalBarShift = iBarShift(Symbol(), Period(), latestDynamicOfAveragesReversalTime);
      int currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);   
   
   double slope = getSuperTrendSlope(0); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);  
      
      Print("==========================================");  
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         //Print("Fake signal at " + (string)getCurrentTime());
      }
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
   
      int latestSignalTimeBarShift = iBarShift(Symbol(), Period(), latestSignalTime);
      currentBarShift = iBarShift(Symbol(), Period(), CURRENT_BAR);        
      
      Print("==========================================");
      
      if( (latestSignalTimeBarShift - currentBarShift) < 2 ) {
         
         //Print("Fake signal at " + (string)getCurrentTime());
      }      
      
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getSomat3AndKalmanBandsSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   double slope = getSomat3AndKalmanBandsSlope(10, 15, 1); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getSomat3AndSeBandsSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   double slope = getSomat3AndSeBandsSlope(10, 10, 1); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getSomat3AndPolyfitBandsSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   double slope = getSomat3AndPolyfitBandsSlope(10, 10, 1); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getVidyaZonesLevelTest() {

   double levels = getVidyaZonesLevel(15, 15, VIDYA_ZONE_MIDDLE, getPreviousBarIndex(CURRENT_BAR)); 
   double priceClosePrev = getPriceClose(getPreviousBarIndex(CURRENT_BAR));


   if(priceClosePrev > levels) {         
      Print("=================VIDYA is BULLISH=========================");
   }
   else if(priceClosePrev < levels) {         
      Print("=================VIDYA is BEARISH=========================");
   }
}

void getStepRSIFloatingLevelTest() {

   //TODO - ADD the test for getStepRSIFloatingExtremeZone
   
   double signal = getStepRSIFloatingLevel(10, 10, 15, 49, FLOATED_STEPPED_RSI_SIGNAL, CURRENT_BAR);
   double fast = getStepRSIFloatingLevel(10, 10, 15, 49, FLOATED_STEPPED_RSI_FAST, CURRENT_BAR); 
   double slow = getStepRSIFloatingLevel(10, 10, 15, 49, FLOATED_STEPPED_RSI_SLOW, CURRENT_BAR);
   double priceClosePrev = getPriceClose(getPreviousBarIndex(CURRENT_BAR));


   if(signal > fast && signal > slow) {         
      Print("=================FLOATED_STEPPED_RSI is BULLISH=========================");
   }
   else if(signal < fast && signal < slow) {         
      Print("=================FLOATED_STEPPED_RSI is BEARISH=========================");
   }
}
void getStepRSIFloatingSlopeReversalTest() {

   Reversal rev = getStepRSIFloatingSlopeReversal(0);
   
   /*if(latestSignal != BUY_SIGNAL && rev == BULLISH_REVERSAL) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && rev == BEARISH_REVERSAL) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }*/     
}
void getStepRSIFloatingExtremeZoneTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }

   Zones zone = getStepRSIFloatingExtremeZone(10, 10, 15, 49, getPreviousBarIndex(CURRENT_BAR)); 
   if( latestSignal != SELL_SIGNAL && zone == BULLISH_EXTREME_ZONE) {      
   
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("=================BULLISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
   else if(latestSignal != BUY_SIGNAL && zone == BEARISH_EXTREME_ZONE)  {       

      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();   
      Print("=================BEARISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
}
void getStepRSIFloatingSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   double slope = getStepRSIFloatingSlope(CURRENT_BAR); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}
void getDynamicRsxOmaExtremeZoneTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      
      return;
   }

   Zones zone = getDynamicRsxOmaExtremeZone(getPreviousBarIndex(CURRENT_BAR)); 
   /*if( latestSignal != SELL_SIGNAL && zone == BULLISH_EXTREME_ZONE) {      
   
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime(); 
      double upperLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
      Print("lowerLevel: " + upperLevel);
      Print("signalLevel: " + signalLevel);
      Print("=================BULLISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
   else if(latestSignal != BUY_SIGNAL && zone == BEARISH_EXTREME_ZONE)  {*/       
   if(zone == BEARISH_EXTREME_ZONE)  { 

 
      double lowerLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
      if(signalLevel > lowerLevel) {
      
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();         
         
         Print("Trigger happy :)");
         Print("lowerLevel: " + (string)lowerLevel);
         Print("signalLevel: " + (string)signalLevel);      
      }
      
      Print("=================BEARISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
}

void getDynamicRsxOmaExtremeZoneReversalTest() {

   Reversal rev = getDynamicRsxOmaExtremeZoneReversal(false);
   
   if(latestSignal != BUY_SIGNAL && rev == BULLISH_REVERSAL) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && rev == BEARISH_REVERSAL) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }     
}

void getCycleKroufrExtremeZoneReversalTest() {

   Reversal rev = getCycleKroufrExtremeZoneReversal(15, 16, 21, false);
   
   if(latestSignal != BUY_SIGNAL && rev == BULLISH_REVERSAL) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && rev == BEARISH_REVERSAL) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }     
}

void getRsiomaBandsZoneReversalTest() {

   Reversal rev = getRsiomaBandsZoneReversal(30, false);
   
   if(latestSignal != BUY_SIGNAL && rev == BULLISH_REVERSAL) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && rev == BEARISH_REVERSAL) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }     
}

void getCycleKroufRLevelExtremeZoneTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      
      return;
   }

   Zones zone = getCycleKroufrExtremeZone(15, 16, 21, CURRENT_BAR);
   if( latestSignal != SELL_SIGNAL && zone == BULLISH_EXTREME_ZONE) {      
   
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime(); 
      double upperLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);

      Print("=================BULLISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
   else if(latestSignal != BUY_SIGNAL && zone == BEARISH_EXTREME_ZONE)  {      

      double lowerLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
      if(signalLevel > lowerLevel) {
      
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();         
      }
      
      Print("=================BEARISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
}

void getRsiomaBandsZonesTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      
      return;
   }

   Zones zone = getRsiomaBandsZones(30, CURRENT_BAR + 1);
   if( latestSignal != SELL_SIGNAL && zone == BULLISH_ZONE) {      
   
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime(); 
      double upperLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_UPPER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);

      Print("=================BULLISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
   else if(latestSignal != BUY_SIGNAL && zone == BEARISH_ZONE)  {      

      double lowerLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
      if(signalLevel > lowerLevel) {
      
         latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();         
      }
      
      Print("=================BEARISH_EXTREME_ZONE=========================@" + (string)getCurrentTime());
   }
   else if(latestSignal != BUY_SIGNAL && zone == TRANSITION_ZONE)  {      

      double lowerLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_LOWER, CURRENT_BAR);   
      double signalLevel = getDynamicRsxOmaLevel(DYNAMIC_RSX_OMA_SIGNAL, CURRENT_BAR);
      if(signalLevel > lowerLevel) {
      
         //latestSignal = BUY_SIGNAL;
         latestSignalTime = getCurrentTime();         
      }
      
      Print("=================TRANSITION_ZONE=========================@" + (string)getCurrentTime());
   }   

}

void getCycleKroufRLevelSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   Slope slope = getCycleKroufRLevelSlope(15, 16, 21); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      //latestSignal = BUY_SIGNAL;
      //latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      //latestSignal = SELL_SIGNAL;
      //latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getDynamicRsxOmaLevelSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   Slope slope = getDynamicRsxOmaLevelSlope(); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      //latestSignal = BUY_SIGNAL;
      //latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      //latestSignal = SELL_SIGNAL;
      //latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}


void getBBnStochOfRsiSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   double slope = getBBnStochOfRsiSlope(CURRENT_BAR); 

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
        
      Print("==========================================");  
            
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
         
      Print("==========================================");
            
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }
}

void getDynamicPriceZonesAndSomat3ReversalTest() {

   Reversal rev = getDynamicPriceZonesAndSomat3Reversal(CURRENT_BAR);
   
   if(latestSignal != BUY_SIGNAL && rev == BULLISH_REVERSAL) {
        
      Print("==========================================");  
            
      //Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && rev == BEARISH_REVERSAL) {
         
      Print("==========================================");
            
      //Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }     
}


//getEftCrossTest and getEftSlopeTest must yield the same results - Avoid entries against the extreme conditions, if OS - dont sell, if OB - don't but
void getEftCrossTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }
   
   Slope slope = getEftSlope(10, CURRENT_BAR);//getEftCrossTest

   if(latestSignal != BUY_SIGNAL && slope == BULLISH_SLOPE) {
      
      Print("==========================================");
      Print("Prev: " + getSignalDescription(latestSignal));      
      Print("Bullish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();           
      Print("==========================================");
   }
   else if(latestSignal != SELL_SIGNAL && slope == BEARISH_SLOPE) {
      
      Print("==========================================");
      Print("Prev: " + getSignalDescription(latestSignal));
      Print("Bearish at: " + convertTimeToString(CURRENT_BAR));
      latestSignal = SELL_SIGNAL;
      latestSignalTime = getCurrentTime();       
      Print("==========================================");
   }  
}
void getEftSlopeTest() {

   if(latestSignalTime == getCurrentTime()) {
      
      return;
   }   

   Slope slope = getEftSlope(10, CURRENT_BAR);
   
   if(slope == BEARISH_SLOPE) {

      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();     
      Print("BEARISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }
   else if(slope == BULLISH_SLOPE) {
      
      latestSignal = BUY_SIGNAL;
      latestSignalTime = getCurrentTime();   
      Print("BULLISH SLOPE SIGNAL at: " + convertCurrentTimeToString());
   }    
}

/* Library */

//TODO - 15-08-2018
//USE SMOOTHED DIGITAL FILTER AS A LEADING INDICATOR

//TODO 27/06/2018
//VOLATILITY_BANDS
//POLYFIT_BANDS
//DIMPA
//Half Trend Channel Goes out of Price Zones. Reversal is eminent
//-Indicator blip-bloop
// MA(5) LW High/Low


//FIX For some reason the previous bar is 2 not 1, both SOMAT3 and STEPPED_TTA

//TODO 17-08-2018 @05:32. ADD the test for getStepRSIFloatingExtremeZone