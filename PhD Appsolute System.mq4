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
//|                                                                  |
//|                                                                  |
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
static string DYNAMIC_OF_AVAERAGES     =  "-PhD DyZOA";
static string DYNAMIC_MPA              =  "-PhD DiMPA";
static string DYNAMIC_EFT              =  "-PhD DiEFT";
static string DYNAMIC_WPR_OFF_CHART    =  "-PhD DiWPR offChart";
static string DYNAMIC_WPR_ON_CHART     =  "-PhD DiWPR onChart";
static string RSI_FILTER               =  "-rsi-filter";

//START BANDS
static string DYNAMIC_MACD_RSI         =  "-PhD DiMcDRsi";
static string DYNAMIC_PRICE_ZONE       =  "-PhD DiPriceZone";
static string STOCHASTIC               =  "-PhD Stochastic v.2";
static string CBF_CHANNEL              =  "-PhD CBF Channel";
static string VOLATILITY_BANDS         =  "-PhD Volatility Bands";   
static string POLYFIT_BANDS            =  "-PhD PolyfitBands";
static string NON_LAG_ENVELOPES        =  "-PhD NonLag Envelopes";
static string DONCHIAN_CHANNEL         =  "-PhD Donchian Channel 2.0";
static string T3_BANDS                 =  "-PhD T3 Bands";
static string BOLLINGER_BANDS          =  "-PhD Bollinger Bands";
static string FIBO_BANDS               =  "-PhD Fibo Bands";
static string SE_BANDS                 =  "-PhD SE Bands";
static string QUANTILE_BANDS           =  "-PhD Quantile Bands";
//END BANDS

//START TRIGGERS
static string LINEAR_MA                =  "-PhD Linear";
static string HULL_MA                  =  "-PhD HMA";
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

enum Reversals {
   BULLISH_REVERSAL,
   BEARISH_REVERSAL,
   CONTINUATION
};

enum Trend {
   BULLISH_TREND,
   BEARISH_TREND,
   NO_TREND
};
/* END local enums */

/*TEMP */
datetime checkedBar = 0;
/* TEMP */


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
   getQuantileBandsReversal();
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

/*Start: DYNAMIC_OF_AVAERAGES Setup */ 
int getDyZOA(bool _validatePreviousbar) {

   
   if( _validatePreviousbar == false) {      

      double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR + 1), Digits); 
      
      double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);


      if( (signalMaCurrent > signalMaPrev) && (signalMaCurrent > lowerMaCurrent)) { 
      
         return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && (signalMaCurrent < upperMaCurrent) ) { 
         
         return OP_SELL; 
      }        
   }
   else { 
      
      // Check previous and current candle

      double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR), Digits);
      
      //We need the value to identify the slope
      double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR + 1), Digits);
      
      
      double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);      
      
      double lowerMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR + 1), Digits);
      double upperMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR + 1), Digits); 
            
      if( (signalMaCurrent > signalMaPrev) && ( (signalMaCurrent > lowerMaCurrent) &&  (signalMaPrev > lowerMaPrev)) ) { 
         
            return OP_BUY; 
      } 
      else if( (signalMaCurrent < signalMaPrev) && ( (signalMaCurrent < upperMaCurrent) && (signalMaPrev < upperMaPrev) )  ) { 
         
         return OP_SELL; 
      }
   }
   
   return -1;
}
/*End: DYNAMIC_OF_AVAERAGES Setup */

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

/*Start: Trend change detection by DYNAMIC_OF_AVAERAGES Setup */ 
int getTrendChangeByDiZOA() {

   double signalMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR), Digits);
   
   //We need the value to identify the slope
   double signalMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 0, CURRENT_BAR + 1), Digits); 
   
   double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR), Digits);
   double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR), Digits);
   
   double lowerMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 1, CURRENT_BAR + 1), Digits);
   double upperMaPrev = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, 20, PRICE_CLOSE, 4, true, 5, 4, CURRENT_BAR + 1), Digits); 

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
/*End: Trend change detection by DYNAMIC_OF_AVAERAGES Setup */

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
double getVolitilityBandsStopLossLevel(int lOrderType, int linitialStopPoints, int band) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR + 1; //Use the previous bar to get a constant and stable stop level. Bands should have changed slope direction
   double volitilityBandsLevel = getVolitilityBandsLevel(band, barIndex);
  
   if (lOrderType == OP_BUY) {
   
      initialStopLossLevel    =  NormalizeDouble( volitilityBandsLevel - (linitialStopPoints * getDecimalPip()), Digits );       
   }
   else if(lOrderType == OP_SELL) {

      initialStopLossLevel    =  NormalizeDouble( volitilityBandsLevel + (linitialStopPoints * getDecimalPip()), Digits );      
   }
 
   return initialStopLossLevel;
}
/** Start - VOLATILITY_BANDS Stop Loss */

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
/** Start - LINEAR_MA Stop Loss */

/** Start - LINEAR_MA Stop Loss */
double getLinearMaStopLossLevel(int lOrderType, int linitialStopPoints, int buffer) {
   
   double initialStopLossLevel  = 0.0; 

   int barIndex = CURRENT_BAR; //Use current bar as the previous will definately be in the direction of the trade for this indicator. 
   //It doesn't not turn immediately, it first spikes to the opposite direction of the trade. 
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

/** Start - DYNAMIC_OF_AVAERAGES Stop Loss */
double getDyZOAStopLevel(int lOrderType, int linitialStopPoints) {
   
   double initialStopLossLevel  = 0.0; 

   if (lOrderType == OP_BUY) {
   
      double lowerMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, CURRENT_TIMEFRAME, 1, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( lowerMaCurrent - (linitialStopPoints * getDecimalPip()), Digits ); 
      
   }
   else if(lOrderType == OP_SELL) {

      double upperMaCurrent = NormalizeDouble(iCustom(Symbol(), Period(), DYNAMIC_OF_AVAERAGES, CURRENT_TIMEFRAME, 4, CURRENT_BAR), Digits);
      initialStopLossLevel    =  NormalizeDouble( upperMaCurrent + (linitialStopPoints * getDecimalPip()), Digits );
   }
 
   return initialStopLossLevel;
}
/** End - DYNAMIC_OF_AVAERAGES Stop Loss */

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

/** START REVERSALS DETECTIONS*/
/** Start - LINEAR_MA Reversal Detection*/
Reversals getLinearMaReversal() {

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
         Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
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
Reversals getNoLagMaReversal() {

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
Reversals getDonchianChannelReversal(bool useClosePrice) {

   if(checkedBar == Time[CURRENT_BAR]) {
      
      return CONTINUATION;
   } 
   
   int upperBuffer   = 0;
   int lowerBuffer   = 1; 
   
   if( getDonchianChannelLevel(useClosePrice, upperBuffer, CURRENT_BAR) == getDonchianChannelLevel(useClosePrice, upperBuffer, CURRENT_BAR + 1) ) { 
      
      checkedBar = Time[CURRENT_BAR];
      Print("BEARISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0) );
      return BEARISH_REVERSAL;       
   }
   if( getDonchianChannelLevel(useClosePrice, lowerBuffer, CURRENT_BAR) == getDonchianChannelLevel(useClosePrice, lowerBuffer, CURRENT_BAR + 1) ) { 
   
      checkedBar = Time[CURRENT_BAR];
      Print("BULLISH_REVERSAL Reversal on " + (string)iTime(Symbol(),CURRENT_TIMEFRAME,0));
      return BULLISH_REVERSAL;     
   }

   return CONTINUATION;
}
/** End - DONCHIAN_CHANNEL Reversal Detection*/

/** Start - QUANTILE_BANDS Reversal Detection*/
Reversals getQuantileBandsReversal() {

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

Trend getDynamicPriceZonesTrend() {

   int midleLevelBuffer = 2;
   
   double priceLevelCurr   = iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR);
   double priceLevelPrev  = iClose(Symbol(), CURRENT_TIMEFRAME, CURRENT_BAR + 1);
   if( (priceLevelCurr > getDynamicPriceZonesLevel(midleLevelBuffer, CURRENT_BAR)) 
         && (priceLevelPrev > getDynamicPriceZonesLevel(midleLevelBuffer, (CURRENT_BAR + 1)))) {
         
         return BULLISH_TREND;
   }
   else if( (priceLevelCurr < getDynamicPriceZonesLevel(midleLevelBuffer, CURRENT_BAR)) 
         && (priceLevelPrev < getDynamicPriceZonesLevel(midleLevelBuffer, (CURRENT_BAR + 1)))) {
         
         return BEARISH_TREND;
   }
   
   return NO_TREND;
}

/** End - DYNAMIC_PRICE_ZONE Level*/

/** Start - LINEAR_MA Level*/
/**
 * Retrieve the LINEAR_MA given buffer value and barIndex
 *
 * 0 = Main, never empty
 * 1 = Up, NOT EMPTY_VALUE even when down trend. Note that upTrendBuffer is never empty, so we can only rely on downTrendBuffer being empty when testing for up trend
 * 2 = Down, EMPTY_VALUE when up trend
 */
double getLinearMaLevel(int buffer, int barIndex) {
   
   int length        = 10;     
   int filterPeriod  = 0; 
   double filter     = 2;  
   double filterOn   = 1.0;   
   return NormalizeDouble(iCustom(Symbol(), Period(), LINEAR_MA, length, PRICE_CLOSE, filterPeriod, filter, filterOn, buffer, barIndex), Digits);
}
/** End - LINEAR_MA Level*/

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
 * 5 = Slope, Upward = 1, Downward = -1 
 */
double getVolitilityBandsLevel(int band, int barIndex) {
   
   int timeFrame     = Period();   
   int  length       = 15;
   double deviation  = 0.5;   
   return NormalizeDouble(iCustom(Symbol(), Period(), VOLATILITY_BANDS, timeFrame, length, deviation, band, barIndex), Digits);   
}
/**
 *  Get the VolitilityBands Slope(5). Upward = 1, Downward = -1.
 */
int getVolitilityBandsSlope(int barIndex) {
   
   int slopeBuffer   = 5; 
   return (int)getVolitilityBandsLevel(slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
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
 * 0 = Main(Upper band) - never empty
 * 1 = value of the middle band -  never empty
 * 2 = value of the lower band -  never empty
 */
double getT3BandsLevel(int band, int barIndex) {
   
   int timeFrame     = Period();   
   int  length       = 6;
   double hot        = 1;
   double deviation  = 1;   
   bool   original = false;
   return NormalizeDouble(iCustom(Symbol(), Period(), T3_BANDS, timeFrame, length, deviation, hot, original, band, barIndex), Digits);
}
/** End - T3_BANDS Level*/

/** Start - DONCHIAN_CHANNEL Level and slope*/
/**
 * Retrieve the DONCHIAN_CHANNEL given buffer value and barIndex
 *
 * 0 = Main(Upper), never empty
 * 1 = Lower band
 * 2 = Middle
 * 4 = Slope
 */
double getDonchianChannelLevel(bool useClosePrice, int buffer, int barIndex) {
   
   int timeFrame        = Period(); 
   int channelPeriod   = 10;
   int highLowShift    = 1;
   bool showMiddle      = false;
   return NormalizeDouble(iCustom(Symbol(), Period(), DONCHIAN_CHANNEL, timeFrame, channelPeriod, highLowShift, showMiddle, useClosePrice, buffer, barIndex), Digits);
}
/**
 *  Get the DONCHIAN_CHANNEL Slope(5). Upward = 1, Downward = -1.
 */
int getDonchianChannelSlope(int barIndex) {
   
   int slopeBuffer   = 4; 
   return (int)getDonchianChannelLevel(slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
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
   return (int)getDonchianChannelLevel(slopeBuffer, barIndex);// It is safe to implicitly cast to int as the slope is either Upward = 1, or Downward = -1.
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



void smoothedDigitalFiltesLevelTest() {
   
   //double upper = getSmoothedDigitalFilterLevel(2, 0);
   //double lower = getSmoothedDigitalFilterLevel(3, 0);
   
   double upper = getQuantileBandsLevel(0, 0); 
   double lower = getQuantileBandsLevel(4, 0);
   
   double upperPrev = getQuantileBandsLevel(0, 1); 
   double lowerPrev = getQuantileBandsLevel(4, 1);   
   
   if(upperPrev == upper) {
      
      Print("UPPER BANDS ARE FLAT at: " + Time[CURRENT_BAR]);
   }
   else if(lowerPrev == lower) {
      
      Print("LOWER BANDS ARE FLAT at: " + Time[CURRENT_BAR]);
   }   
}