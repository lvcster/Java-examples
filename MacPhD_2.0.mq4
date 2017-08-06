//+------------------------------------------------------------------+
//|                                                 PhDIndicator.mq4 |
//|                                      Copyright 2016, PhD Systems |
//|                                      https://www.phdinvest.co.za |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, PhD Systems"
#property link      "https://www.phdinvest.co.za"
#property version   "1.0" //2017-03-21: 
//                   // TODO implemnt curve 0 test, divergence as well
//                   "1.1" //2017-02-28: Added noise filters V1 - isFilteredNoiseByDamianiVolatmeterV0
//                    2.0 2017-03-21: 1 - Added && (previousMainLevel > 0) on isMACDHistogramBuy() method to make sure the previous bar is greater than 0 - this means the 1st 2 bars must be bullish
//                                    2 - Added && (previousMainLevel < 0) on isMACDHistogramSell() method to make sure the previous bar is less than 0 - this means the 1st 2 bars must be bearish
//                    3.0 2017-03-22: Added isMaAscending() and isMaDescending() methods to make sure we only enter when the ema is heading to the intended direction
//                    4.0 2017-03-24:18H25   1.  Added isTwoMaCross() to only enter after the cross 
//                                           2.  BE in Progress. - Move the SL to BE after x number of pips movement
//                                           3.  Close order when Histogram crosses to the opposite side of the trade
//                                           4.  Added instance variables to track histogram crossing
//                                           5.  Added check for longTermTrendGauge - but not used
//                    5.0 2017-03-26:19H26   1. Added PSAR trailing stop
//                                           
//                    6.0 2017-03-28:16H07    Removed MacD signal checks as it seems to be a redundant
//                    7.0 2017-03-28:16H38    Added the functionality to allow following the trend if opted to do so
//                    8.0 2017-03-28:22H25    Added takeProfit method to TP after x amount of pips movement
//                    9.0 2017-03-29:23H29    Added isHeikenAshiSmoothBullishColorChange and isHeikenAshiSmoothBearishColorChange - Still in Testing
//                                           
//                                           Todo - Check if PSAR/HA can be used to TP(and avoid leaving money on the table)
//                                           Todo - Improve TS/BE as some wins turn into loses
//                    10.0 2017-04-02: Added isIchimokuBuy() and isIchimokuSell() methods to incorporate Ichimoku Kinko Hyo indicator
//                    10.0 2017-04-02: Not yet implemented
//
//                    11.0 2017-04-03:23H59 Added isPriceNested() to make sure no trade is traken when price is nested in Ichimoku Konki Hiyo
//
//                    11.0 2017-04-03:23H59 TODO - close immediately when price goes over kijun-sen in the opp direction. Appears to yield optimal results
//
//                    12.0 2017-04-05:23H41 - Added the following methods, but not yet used
//                                                   //isChikouSpanAbovePriceClose
//                                                   //isChikouSpanBelowPriceClose
//                                                   //isRsiOverbought
//                                                   //isRsiOverSold
//                                                   //isIchimokuSell
//                                                   //isIchimokuBuy
//                    12.0 2017-04-10:17H53 - Added RSI and Stock - trade setups, extreme confitions
//                    TODO 2017-04-09:08H40 - Implement Incremental magic number to make every trade unique
//                    TODO 2017-04-20:21H47 - When the previous trade is closed and the next trade suggest to go the opposite direction, the previous swing low/high should have been broken.
//                    
//                    13.0 2017-04-21:23H57 - Changed to close using RSI extreme conditions instead of MacD 0 Transition
//
//                    14.0 2017-04-28:00H28 - Added isMaCrossStrongBuy(fastEma, slowEma) and isMaCrossStrongSell(fastEma, slowEma) - they can be reused for any EMA combinations
//                                          - Added isTrippleMAIntersectionBuy(fastEma, mediumEMA, slowEma) and isMaCrossStrongSell(fastEma, slowEma) - they can be reused for any 3 EMA intersectyions
//
//                    15.0 2017-05-01:23H20 -15.1 Introduced isMacDTransitionBuySetup and isMacDTransitionSellSetup for the old MACD transition. Still works the same
//                                          -15.2 Introduced EMA Crossing: isDoubleMaCrossBuySetup and isDoubleMaCrossSellSetup. To assist MACD transition missed trade due to noise
//                                           -15.2.1 Still need improvements, filters, trend following, etc
//                                          -15.3 isTrippleMAIntersectionBuy and isTrippleIntersectionMASell strategy still in dev and testing
//                                          -15.4 Added capability to select which strategy to use in runtime

//                    16.0 2017-05-08:16H24 -15.1 isStrongBuySignal and isStrongSellSignal - they encapsulate checks for 

                                             /*1. Check HA smoothed Trend */
                                                /* 1.1 Previous 2 bars are bullish/bearish */
                                                /* 1.2 Current bar is bullish/bearish */
                                             /*2. Check Price action above/below HA smoothed*/
                                             /*3. Check HA smoothed is above/below Moving Average*/
                                             /*4. Check Fast and Medium MA crossing*/
//                    17.0 2017-05-17:22H50 -17.0 heck HA smoothed checks - Slowing down, and might not even be required                                         

//                    18.0 2017-05-20:09H51 -18.0 Combine Zero transition and Double MA cross 
//                    18.1 2017-05-21:19H38 -18.1 Introduced a condition to close on MA cross - Preferably 5M TF
//                    18.2 2017-05-21:20H09 -18.3 Introduced a option to select on timeframe on which to check RSI extreme conditions

//                    19.0 2017-05-21:20H20 -19.0 Remove HA Smoothed code
//                    20.0 2017-05-22:23H36 -20.0 Re-enter when price goes above/below MA after retracing - Short TF(5 min) can help by confirming the cross
//                                                In progress..isDoubleMaCrossBuyRetracement and isDoubleMaCrossSellRetracement

//                    21.0 2017-05-24:00H05 -21.0 Added getLondonBreakOut
//                    21.1 2017-05-29:21H20 -21.1 Improved. Both buy and sell working
//                                                In progress (Apply no BE, Target 30 pips - Looks good on EURUSD)
                     
//                    22.0 2017-05-29:21H22 -22.0 Added getFivenOneMaCrossBuy and getFivenOneMaCrossSell -- in progress

//                    23.0 2017-06-01:23H16 -23.0 Split getLondonBreakOut into getLondonBreakOutBuy and getLondonBreakOutSell -- in progress
//                                          -TODO Bug - Allow only 1 trade per day. There's multiple trade at the moment

//                    24.0 2017-06-07:23H30 -24.0 Added SuperTrendCrossScalp strategy isSuperTrendCrossScalpSellSignal and isSuperTrendCrossScalpBuySignal
//                                          -In progress

//                                          -TODO Rework use5MDoubleMaCross
//                                          -TODO DoubleMaCross, current MacD Histogram must be higher/ lower than the previous one

//                    30.0 2017-06-16:14H30 -30.0 Major milestone - Added 55 EMA Strategy

//                    31.0 2017-06-20:23H10 -31.0 Added methods to track CCI levels. Methods are getCciZeroLevelStatus, getCciHundredLevelStatus, etc

//                    32.0 2017-06-23:23H14 -32.0 Added CCI Strategy - Inprogress. 
//                                           TODO: FIX CCI BUG(Fake CCI14 Cross) on EURUSD 2017-01-10 2017-01-11 Test date

//                    33.0 2017-06-29:22H51 -33.0 Added GMMA Strategy - Inprogress
//                                           TODO: If the the first 3 points(120.123**) of both fast and slow MAs were equal on previous bar, and the fast MA spread on the current bar: potentail trade setup
//                                           TODO: 200MA price cross and the short term trend sentiment

//                    34.0 2017-07-02:17H12 -34.0 Added condition to close on RSI extreme conditions - default to false. This made a huge difference in terms of profit.

//                    MacPhD2.0              2017-07-30 
//                                           SL/TP in Progress. M: 3-5, M5: 5-10, M15: 15-20, M30: 25-30, 1H 40-60, 4H: 80-100, D: 150 - 200
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
int currentTrend;   // Get currentTrend
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
extern bool closeOnCciTrendReversal       =  false;


//--------TRADE SETUP ATTRIBUTES-----------
int previousTrade =  -1; 
extern string TRADE_SETUP_ATTRIBUTES;     //--------TRADE SETUP ATTRIBUTES----------
extern bool rideTrend                     =  false;
// Re-Enter after TP or SL(When conditions are met) on the same trend
extern bool reEnterOnNextSetup            =  true;  

//--------TRADE SETUP FILTERS-------------- 
extern string TRADE_SETUP_FILTERS;        //--------TRADE_SETUP_FILTERS-------------   
//We use EMA relative to the price action set initial stops
extern int initialStopMaPeriod            =  55;
extern int trailingStopMaPeriod           =  55;
extern int phdTrendGauge                  =  55;
extern int longTermTrendGauge             =  200;
extern bool filterByLongTermTrend         =  true;

//filters
extern bool filterByAdx                =  false;
extern bool filterByAdxTrendDirection  =  true;
extern bool filterByBollingerBands     =  true;
extern bool filterStochasticExtemes    =  false;
extern bool filterRsiExtremes          =  false;
extern bool filteredByPsar             =  true; 
extern bool filteredByChikouSpan       =  true;
extern bool filteredByIchimokuCloud    =  false;
extern bool filterByDamianiVolatmeterV0            =  false;
extern bool filteredByRsiExtremeConditions         =  false;
extern bool applyAggresiveExtremeConditionsTrades  =  false;

//--------MONEY MANAGEMANT-----------------
// Money Management
bool isMoneyManagementEnabled             =  false;
int lotDecimalPlaces                      =  2;
double risk                               =  2;
bool alreadyModified                      = false; // Global variable to track if order has already been modified
int trailingStopPointsOnHAChangeColor     =  10;
extern string MONEY_MANAGEMANT;           //--------MONEY MANAGEMANT----------------
extern double volume                      =  0.02; //volume
extern bool closeOnRsiExtremeConditions   = false;
extern int numberOfBarsToTrack            =  5;
extern int trailingStopPoints             =  10;   
extern int targetPointsTrailingStop       =  20; 
extern int targetPointsBeforeTrailingStop =  20;
extern int expectedMovementToKeepOpenTrade=  20;
extern int initialStopPoints              =  20;
extern int breakEvenTargetPoints          =  30;
extern int initialTargetPoints            =  70;
extern bool applyBreakEven                =  true;
extern bool applyTakeProfit               =  true;
extern bool applyThreeMaCrossStop         =  false;
extern bool forceCloseOnOppositeSignal     =  false;
extern bool exitOnPriceGoingAgainstOpenTrade =  false;
extern ENUM_TIMEFRAMES rsiExtremeConditionsTimeFrame =  PERIOD_H1;

//--------MISCELLANEOUS---------- 
extern bool debug = false;

/** MA */
int MA_SHIFT                  =  0; // Moves the resulting line into the future or the past. Default to 0(Most common) to move the line to the current bar
int MA_METHOD                 =  MODE_EMA; // Exponential Moving Average
int PRICE_ACTION_CLOSE_MA     =  1; // Exponential Moving Average

/** 2 LINE MACD */
int TWO_LINE_MACD_BUFFER            =  1;
int TWO_LINE_MACD_SIGNAL_BUFFER     =  2;
int TWO_LINE_MACD_FAST_EMA_PERIOD   =  12;
int TWO_LINE_MACD_SLOW_EMA_PERIOD   =  26;
int TWO_LINE_MACD_SIGNAL_EMA_PERIOD =  1;

/* 
   Global variables used in isMACDHistogramBuy and isMACDHistogramSell, to keep track of the 0 transition. They will be used to check is Macd setup is still intact
   should other setups arises after the current MacD setup was not used because of filters.
*/
bool isMACDHistogramSell   =  false;
bool isMACDHistogramBuy    =  false;
        
/** ICHIMOKU */
int KIJUN_SEN_PERDIOD      =  26;
int TENKAN_SEN_PERDIOD     =  9;
int SENKOU_SPAN_B_PERDIOD  =  52;

/** RSI */
extern int rsiMedianLevel  =  50;
int PHD_RSI_DEFAULT_PERIOD =  14;
int RSI_OVERSOLD_LEVEL     =  30;
int RSI_OVERBOUGHT_LEVEL   =  70;

/** PhD MA */
int THREE_EMA_FAST         =  13;
int THREE_EMA_MEDIUM       =  34;
int THREE_EMA_SLOW         =  55;

/** Parabolic SAR */
double PSAR_PRICE_INCREMENT_STEP       =  0.02;
double PSAR_MAX_PRICE_INCREMENT_STEP   =  0.2;

/** Stochastic */
int STOCH_OVERSOLD_LEVEL   =  20;
int STOCH_OVERBOUGHT_LEVEL =  80;
int STOCH_SLOWING    =  3;
int STOCH_D_PERIOD   =  3;
int STOCH_K_PERIOD   =  21;

/** Bollinger bands */
int STANDARD_DEV = 2;
int DEFAULT_BB_PERIOD = 20;

/** Average Directional Movement Index */
int PHD_ADX_PERIOD = 14;

/** Extreme conditions */
int OVERSOLD_CONDITION        =  0;
int OVERBOUGHT_CONDITION      =  1;
bool isRsiOverSold            =  false;
bool isRsiOverBought          =  false;
bool isStochasticOverBought   =  false;
bool isStochasticOverOverSold =  false;

/** Tripple MA Interaction  Strategy. 3 MAs cross each other within limited number of bars*/
extern string TRIPPLE_INTERSECTION;    //--------TRIPPLE INTERSECTION----------------
extern int trippleMAIntersectionBarsToProcess   =  10;


/** Tripple MA cross Strategy. 3 MAs cross each other within unlimited number of bar*/
//extern string TRIPPLE_CROSS;           //--------TRIPPLE CROSS----------------
datetime slowMACrossTime                 =   0;
datetime fastMACrossTime                 =   0;
datetime trippleMACrossTime              =   0;

/** CCI */
int CCI_PERRIOD                  =  50;
int CCI_ZERO_LEVEL               =  0;
int CCI_POSITIVE_HUNDRED_LEVEL   =  100;
int CCI_NEGATIVE_HUNDRED_LEVEL   =  -100;
enum CciLevelsEnum {
   CCI_INVALID                   =  0,
   CCI_ABOVE_ZERO                =  1,
   CCI_BELOW_ZERO                =  -1,
   CCI_ABOVE_POSITIVE_HUNDRED    =  100,
   CCI_BELOW_NEGATIVE_HUNDRED    =  -100
};

/** Strategies */
extern string STRATEGIES;              //--------STRATEGIES----------------
extern bool useQQE                  =  true;
extern bool useEnvelopes            =  true;
extern bool useGmma                 =  true;
extern bool useCciStrategy          =  true;
extern bool useMacDTransition       =  true;
extern bool useDoubleMaCross        =  true;
extern bool useMaAndPriceClose      =  true;
extern bool useSuperTrendCrossScalp =  false;
extern bool use5MDoubleMaCross      =  false;
extern bool usePriceAndEma          =  false;
extern bool useLondonBreakOut       =  false;
extern bool useShortOnLongTimeFrame       =  false;
extern bool useDoubleMaCrossRetracement   =  false;
extern bool useRsiBBStrategy  =  false;

/** Used candle trackers */
int londonBreakOutBuyUsedDayOfWeek  =  0;
int londonBreakOutSellUsedDayOfWeek =  0;
datetime tradeExecutionTime         =  0;
datetime slowMAIntersectionTime     =  0;
datetime fastMAIntersectionTime     =  0;
datetime trippleMAIntersectionTime  =  0;
datetime londonBreakOutBuyTime      =  0;
datetime londonBreakOutSellTime     =  0;
datetime fivenOneMaCrossTime        =  0;
datetime superTrendCrossScalpBuyTime   =  0;
datetime cciStrategyTradeExecutionTime =  0;
datetime superTrendCrossScalpSellTime  =  0;
datetime londonBreakLowestPriceProcessedTime       =  0;
datetime londonBreakOutHighestPriceProcessedTime   =  0;

/** Signal trackers */
int QQESignalTracker             = -1; //Track to ensure that signal is only used once - When is it still fresh
int envelopesSignalTracker       = -1; //Track to ensure that signal is only used once - When is it still fresh
int gmmaSignalTracker            = -1; //Track to ensure that signal is only used once - When is it still fresh
int cciZeroLevelStatus           = -1; //Tracks whether cc1 has crossed above/below 0
int cciHundredLevelStatus        = -1; //Tracks whether cc1 has crossed above/below 100 or above/below -100
int priceCloseAndMaSignalTracker = -1; //Track to ensure that signal is only used once - When is it still fresh
int useCciStrategyStatus         = -1; //Track to ensure that signal is only used once - When is it still fresh
int rsiBBStrategySignalTracker   = -1; //Track to ensure that signal is only used once - When is it still fresh

/** Breakout sessions */
extern string BREAKOUTS;              //--------BREAKOUTS----------------
extern int breakOutBarsEndIndex     =  5;
extern int breakOutBarsStartIndex   =  1;
extern int londonBoSessionOpenHour  =  10;
extern int londonBoExitTradeHour    =  17;
double londonBreakOutLowestPrice    =  0;
double londonBreakOutHighestPrice   =  0;
extern ENUM_APPLIED_PRICE appliedPrice = PRICE_HIGH;
extern bool isExitTradeOnLondonBoExitTradeHour =  true;
double initialLondonBreakOutBuyStopLevel        =  0.0;
double initialLondonBreakOutSellStopLevel       =  0.0;
double initialLondonBreakOutBuyTakeProfitLevel  =  0.0;
double initialLondonBreakOutSellTakeProfitLevel =  0.0;
extern int initialLondonBreakOutStopPoints      =  5; 
extern int initialLondonBreakOutTakeProfitPoints=  20; 
/** Breakout sessions */

/** Super Trend Cross Scalp*/
extern string SUPER_TREND_CROSS_SCALP;              //--------SUPER TREND CROSS SCALP----------------
extern int SUPER_TREND_CROSS_SCALP_FAST_MA         =  9; 
extern int SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA   =  5; 
/** Super Trend Cross Scalp */

/** GMMA STRATERGY*/
extern int gmmaRoundingPrecision = 4;
/** GMMA STRATERGY*/

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
      
   int tradeSetup  =  getTradeSetup(); 
      
   // Track market conditions
   processExtremeConditions();
   
   double lVolume = GetLots();
   
   //TO Use MathMax and MathMin to determine the > or <
   
   /**processTradeManagement(); // check for open trade and move trailing stops and TP when necessary
    *If TP/SL/Manual close, reset variables when this happens as still set to the previos buy/sell setup
    */

   if (OrdersTotal() > 0) {
      
      processTradeManagement(breakEvenTargetPoints, trailingStopPoints, targetPointsBeforeTrailingStop, CURRENT_BAR + 1 );
      
      //TODO return here - processTradeManagement will handle the biz

   } 
   else {
      if (reEnterOnNextSetup) {
         resetTradeSetupAttributes();
      }
   }
     
   /*if(isRsiOverBought(CURRENT_TIMEFRAME, CURRENT_BAR + 1)) {
      Print(" Buy ");   
   }   
   
   else if (isRsiOverBought(CURRENT_TIMEFRAME, CURRENT_BAR + 1)) {
      Print(" Sell ");   
   }
   return;*/
   /*if(isFastGmmaBuySignal(PERIOD_H1, CURRENT_BAR) && isSlowGmmaBuySignal(PERIOD_H1, CURRENT_BAR)) {
      Print(" Buy Sir ");   
   }   
   
   if (isFastGmmaSellSignal(PERIOD_H1, CURRENT_BAR) && isSlowGmmaSellSignal(PERIOD_H1, CURRENT_BAR) ) {
      Print(" Sell Sir");   
   }
   */
   testQQE();
   return; 

   // Receive singnal
   // New candle has to form after the cross

   // All condtions met, place order.
   
   //find a way to associate magic number and ticket number to ensure we closing the correct order
   
   // Do some logging
   // Will it be worthwhile to expire an order?
   int ticket = 0;
   // Positions must only be changed if ticket was created
   if (isInLongPosition == false && (tradeSetup == OP_BUY)) { 

      if (rideTrend == false && initialTrendSetUp == OP_BUY) { 
         return;
      }      
      
      initialTrendSetUp        =  OP_BUY;
      alreadyModified   =  false;
   
      if (OrdersTotal() > 0 && isInShortPosition == true) {
      
         if ( forceCloseOnOppositeSignal == false ) { 
            
            //There's already a SELL trade, wait for its SL to hit(if it will) before opening BUY trade
            return;
         
         }    
         else {
         
            // Force close the SELL trade before the SL hits
            if (CloseOrder(retries)) {
               isInShortPosition = false; //reset only when we guaranteed that the OP_SELL order type has been closed
            }
            else {
            //Log any errors
            }
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
      ticket = PlaceOrder(OP_BUY, lVolume, comment, BUY_MAGIC_NUMBER, Green);

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

         if ( forceCloseOnOppositeSignal == false ) { 
            
            //There's already a BUY trade, wait for its SL to hit(if it will) before opening SELL trade
            return;
        
         }    
         else {

            // Force close the BUY trade before the SL hits
            if (CloseOrder(retries)) {
               isInLongPosition = false; //reset only when we guaranteed that the OP_BUY order type has been closed
            }
            else {
               // Log errors
            } 
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
      ticket = PlaceOrder(OP_SELL, lVolume, comment, SELL_MAGIC_NUMBER, Red);
      
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

   //Exit logging method name  
}

// Check if ticket != -1, Call GetLastError() if it is to retrive error details
int PlaceOrder(int lOrderType, double lVolume, string orderComment, int lMagicNumber, color arrowColor) {

   string methodName = "PlaceOrder";
   
   double price            =  0.0;
   double initialStopLevel =  0.0;
   double takeProfitPrice  =  0.0;
   int slippagePrice       =  getSlipage(slippage);  
  
   RefreshRates(); // To make sure that we have the update data(price action details)
   if (lOrderType == OP_BUY) {
   
      price =  Ask; 
      
      if ( useLondonBreakOut) {
   
         initialStopLevel  =  initialLondonBreakOutBuyStopLevel;
         takeProfitPrice   =  initialLondonBreakOutBuyTakeProfitLevel;
      }
      else if(useRsiBBStrategy) {
      
         double previousPriceClose = iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
         takeProfitPrice   =  NormalizeDouble(Ask + (300 * Point), Digits);      
         initialStopLevel  =  NormalizeDouble( Bid - (150 * Point), Digits);
         
         Print("OP_BUY, Ask: " + Ask) ;
         Print("SL: " + initialStopLevel) ;
    
      }      
      else {
      
         initialStopLevel  =  getInitialStopLevel(OP_BUY, initialStopPoints);//D=30
         takeProfitPrice   =  getInitialTakeProfit(OP_BUY, initialTargetPoints); //D=200
      }
      
      
   }
   else if(lOrderType == OP_SELL) {
      
      price =  Bid; 
      
      if ( useLondonBreakOut) {
   
         initialStopLevel  =  initialLondonBreakOutSellStopLevel;
         takeProfitPrice   =  initialLondonBreakOutSellTakeProfitLevel;
      }
      else if(useRsiBBStrategy) {
      
         double previousPriceClose = iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
         takeProfitPrice   =  NormalizeDouble(Bid - (300 * Point), Digits);      
         initialStopLevel  =  NormalizeDouble( Ask + (150 * Point), Digits); 
         
         Print("OP_SELL, Bid: " + Bid) ;
         Print("SL: " + initialStopLevel) ;
               
      }      
      else {
      
         initialStopLevel  =  getInitialStopLevel(OP_SELL, initialStopPoints);
         takeProfitPrice   =  getInitialTakeProfit(OP_SELL, initialTargetPoints);
         
         Print("OP_SELL, Bid: " + Bid) ;
         Print("SL: " + initialStopLevel) ;           
      }
      
   }
   
   return OrderSend(SYMBOL, lOrderType, lVolume, price, slippage, initialStopLevel, takeProfitPrice, orderComment, lMagicNumber, ORDER_EXPIRATION_TIME, arrowColor);
}

void processTradeManagement(int lBreakEvenPoints, int lTrailingStopPoints, int lTargetPointsBeforeTrailingStop, int pastCandleIndex) {

   if(useRsiBBStrategy) {
      
      return;
   }
   
   if(useQQE) {
      
      return;
   } 
   
   if(useEnvelopes) {
      
      return;
   }        
   
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
      
         if ( useLondonBreakOut) {
            
            if( (Hour() == londonBoExitTradeHour) )  {
            
             // close any London BO trades if any
               if (CloseOrder(retries)) {
                  
                  isInLongPosition  = false; 
                  isInShortPosition = false;
                  initialLondonBreakOutBuyStopLevel = 0.0; 
                  initialLondonBreakOutSellStopLevel= 0.0;                
                  initialLondonBreakOutBuyTakeProfitLevel  =  0.0;
                  initialLondonBreakOutSellTakeProfitLevel =  0.0;                  
               }                  
            }
            
            return;                  
         }
         
         else {
            // Amongst the open order, 1 is for this Symbol - test if order modification is required
            
            // Only open orders and current symbol
            if ( OrderCloseTime() == 0 && OrderSymbol() == SYMBOL) { 
            
               if (OrderType() == OP_BUY ) { 
               
                  if ( closeOnCciTrendReversal && isCciBuyTrendReversal(50) ) {
                     if (CloseOrder(retries)) {
                        
                        /* Reset Strategies attributes to default */
                        priceCloseAndMaSignalTracker = -1;
                        isInLongPosition  = false;
                        return;                        
                     }                   
                  }
                  
                  // Manage CCI Strategy trades
                  if ( useCciStrategy ) {    
                  
                     if ( (cciStrategyTradeExecutionTime != Time[CURRENT_BAR]) && ( (getCciLevel(50) == CCI_BELOW_ZERO) || (getCciLevel(50) == CCI_BELOW_NEGATIVE_HUNDRED) 
                           || isCciGoingBelowPositiveHundredLevel(50) || isCciGoingBelowPositiveHundredLevel(200)) ) {
                        
                        if (CloseOrder(retries)) {
                           
                           Print(" Close time " + cciStrategyTradeExecutionTime);
                           Print(" Management: Order open time" + OrderOpenTime());
                           
                           isInLongPosition  = false;
                           useCciStrategyStatus = -1;
                           return;                        
                        }                      
                     }
                  
                     return;
                  }                  
               
                  // Manage MA 55 Cross Strategy
                  if ( useMaAndPriceClose) {          
                       
                     if ( isPriceCloseBelowMiddleBand(55) == true ) {
   
                        /* Price cross to the opposite of the open trade, close the trade*/
                        if (CloseOrder(retries)) {
                           
                           priceCloseAndMaSignalTracker = -1;
                           isInLongPosition  = false;
                           return;                        
                        }                  
                     
                     }  
                  }             
               
                  if ( useSuperTrendCrossScalp) {
                     
                     // Exit trade if MAs cross to small time down trend
                     if ( isSlowMaAboveFastMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR)) { 
                        if (CloseOrder(retries)) {
                        
                           isInLongPosition = false; 
                        }                      
                        return;
                     }
                  }         
               
                  RefreshRates();
                  
                  double currentPriceHigh                   =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
                  double pointsMoved                        =  NormalizeDouble( (Ask - OrderOpenPrice()), Digits);
                  double decimalTargetPoints                =  NormalizeDouble( (getDecimalPip() * initialTargetPoints), Digits );
                  double decimalTargetPointsBeforeBreakEven =  NormalizeDouble( (getDecimalPip() * breakEvenTargetPoints), Digits );
                  
                  if( closeOnRsiExtremeConditions && isRsiOverBought(rsiExtremeConditionsTimeFrame, CURRENT_BAR) ) {
                     
                     if (CloseOrder(retries)) {
                       
                        isInLongPosition = false; 
                     }
                     else {
                     //Log any errors
                     }
                     
                     return;                
                  }
                  
                  double currentPsarLevel   =  NormalizeDouble( iSAR(SYMBOL, CURRENT_TIMEFRAME, PSAR_PRICE_INCREMENT_STEP, PSAR_MAX_PRICE_INCREMENT_STEP, CURRENT_BAR), Digits);
                  if (breakEven == true && (currentPriceHigh < currentPsarLevel) ) {
                     
                     isModifyTrailingStop(OP_BUY, lTrailingStopPoints, false);
                     return;                  
                  }                 
                  
                  if (breakEven == true && (pointsMoved >= decimalTargetPoints) ) {
   
                     takeProfit(OP_BUY);
                     return;
                  } 
                  
                  // Move SL to BE(entry point when reached lBreakEvenPoints)
                  if (breakEven == false && ( ( pointsMoved >= decimalTargetPointsBeforeBreakEven) ) ) {
                     
                     // Must only execute once
                     breakEven = breakEven(OrderTicket(), OrderOpenPrice(), OP_BUY);
                     return;
                  }  
                  
               } //end OP_BUY test
      
               else if( OrderType() == OP_SELL) { 
               
                  if ( closeOnCciTrendReversal && isCciSellTrendReversal(50) ) {
                     if (CloseOrder(retries)) {
                        
                        /* Reset Strategies attributes to default */
                        priceCloseAndMaSignalTracker = -1;
                        isInLongPosition  = false;
                        return;                        
                     }                   
                  }               
                  
                  // Manage CCI Strategy
                  if ( useCciStrategy) {
                  
                     if ( (cciStrategyTradeExecutionTime != Time[CURRENT_BAR]) && ( (getCciLevel(50) == CCI_ABOVE_ZERO ) || (getCciLevel(50) == CCI_ABOVE_POSITIVE_HUNDRED) 
                           || isCciGoingAboveNegativeHundredLevel(50) || isCciGoingAboveNegativeHundredLevel(200) ) ) {
                        
                        if (CloseOrder(retries)) {

                           isInShortPosition    = false;                           
                           useCciStrategyStatus = -1;
                           return;                        
                        }                      
                     }                            
                       
                     return; 
                  }                   
               
                  if ( useMaAndPriceClose) {
                  
                     if ( isPriceCloseAboveMiddleBand(55) == true ) {
   
                        /* Price cross to the opposite of the open trade, close the trade*/
                        if (CloseOrder(retries)) {
                           
                           priceCloseAndMaSignalTracker = -1;                        
                           isInShortPosition = false;
                           return;
                        }                  
                     
                     }               
                  }               
               
                  if ( useSuperTrendCrossScalp) {
                     
                     // Exit trade if MAs cross to small time down trend
                     if ( isFastMaAboveSlowMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR)) { 
                        if (CloseOrder(retries)) {
                        
                           isInLongPosition = false; 
                        }                      
                        return;
                     }
                  }                 
               
                  RefreshRates();
                  
                  double pointsMoved                           =  NormalizeDouble( (OrderOpenPrice() - Bid), Digits);
                  double currentPriceHigh                      =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
                  double decimalTargetPoints                   =  NormalizeDouble( (getDecimalPip() * initialTargetPoints), Digits );               
                  double decimalTargetPointsBeforeBreakEven    =  NormalizeDouble( (getDecimalPip() * breakEvenTargetPoints), Digits );  
                  
                  if ( closeOnRsiExtremeConditions && isRsiOverSold(rsiExtremeConditionsTimeFrame, CURRENT_BAR) ) {

                     if (CloseOrder(retries)) {
                        isInShortPosition = false; 
                     }
                     else {
                     //Log any errors
                     }  
                     return;                                                
                  }               
   
                  double currentPsarLevel   =  NormalizeDouble( iSAR(SYMBOL, CURRENT_TIMEFRAME, PSAR_PRICE_INCREMENT_STEP, PSAR_MAX_PRICE_INCREMENT_STEP, CURRENT_BAR), Digits);                            
                  if (breakEven == true && (currentPriceHigh > currentPsarLevel) ) { 
                     
                     isModifyTrailingStop(OP_SELL, lTrailingStopPoints, false);
                     return;                  
                  }
                                 
                  if (breakEven == true && (pointsMoved >= decimalTargetPoints) ) {
   
                     takeProfit(OP_BUY);
                     return;                  
                  }        
                  
                  // Move SL to BE(entry point when reached lBreakEvenPoints)
                  if (breakEven == false && ( ( pointsMoved >= decimalTargetPointsBeforeBreakEven) ) ) {
                    
                     // Must only execute once
                     breakEven = breakEven(OrderTicket(), OrderOpenPrice(), OP_SELL);
                     
                     return;
                  } 
                  
               } //end OP_SELL test
                
               // if this return has been matched, exit the iteration as there should only be 1 macth as per the design of this EA
               //return;
               
            } // end OrderCloseTime() && OrderSymbol() test
      
         } // end London BO
      
      } // end OrderSelect()
   
   } // end OrdersTotal()
}

/**
  * lOrderType: OP_BUY or OP_SELL
  * linitialStopPoints: Number of pips acceptable to loose if the losing trade
  */
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

/**
  * lOrderType: OP_BUY or OP_SELL
  * lTrailingStopPoints: Number of pips acceptable to move TS towards the money
  */
bool isModifyTrailingStop(int lOrderType, int lTrailingStopPoints, bool isTrailOnHAColorChange) {
   
   double orderPrice = 0.0;
   double trailingStopLossLevel  = 0.0; 
   
   double currentPriceHigh =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double currentPsarLevel =  NormalizeDouble( iSAR(SYMBOL, CURRENT_TIMEFRAME, PSAR_PRICE_INCREMENT_STEP, PSAR_MAX_PRICE_INCREMENT_STEP, CURRENT_BAR), Digits);
      
   
   if (lOrderType == OP_BUY) {
   
      if (isTrailOnHAColorChange) {
         
         double previousOpen  =  iOpen(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
         trailingStopLossLevel =  NormalizeDouble( previousOpen - (trailingStopPointsOnHAChangeColor * getDecimalPip()), Digits );
      
      } // end isTrailOnHAColorChange
      else {

         // Only move when there's bearish PSAR formed
         if (currentPriceHigh < currentPsarLevel) {
   
            double maPreviousLevel  =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, trailingStopMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR), Digits);
            trailingStopLossLevel =  NormalizeDouble( maPreviousLevel - (lTrailingStopPoints * getDecimalPip()), Digits );
         
         } // end currentPriceClose < currentPsarLevel
         
      }
      
      if ( OrderStopLoss() == 0 || OrderStopLoss() < trailingStopLossLevel ) {
               
         if ( !OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopLossLevel, OrderTakeProfit(), ORDER_EXPIRATION_TIME, Black)) {
         
            // TODO If can't be modified, then close it
            Print( "In modifyTrailingStop. Error when modifying TS: " + ErrorDescription(GetLastError()));
            return false;       
         }         
         else {
            Print( "In isModifyTrailingStop: Modifying BUY Trailing Stop"); 
            return true;
         }  
                         
      } // end OrderStopLoss() == 0 || OrderStopLoss() < trailingStopLossLevel
      

   } // end lOrderType == OP_BUY
   
   else if(lOrderType == OP_SELL) {

      if (isTrailOnHAColorChange) {
         
         double previousOpen  =  iOpen(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
         trailingStopLossLevel =  NormalizeDouble( previousOpen + (trailingStopPointsOnHAChangeColor * getDecimalPip()), Digits );      
         
      } // end isTrailOnHAColorChange
      
      else {   
   
         // Only move when there's bullish PSAR formed
         if (currentPriceHigh > currentPsarLevel) {   
            
            double maPreviousLevel  =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, trailingStopMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR), Digits);
            trailingStopLossLevel   =  NormalizeDouble( maPreviousLevel + (lTrailingStopPoints * getDecimalPip()), Digits );
            
         } // end currentPriceClose > currentPsarLevel
      }
      
      if ( OrderStopLoss() == 0 || OrderStopLoss() > trailingStopLossLevel ) {
      
         if ( !OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopLossLevel, OrderTakeProfit(), ORDER_EXPIRATION_TIME, Black)) {
         
            // TODO If can't be modified, then close it
            Print( "In modifyTrailingStop. Error when modifying TS: " + ErrorDescription(GetLastError()));
            return false;       
         }         
         else {
            Print( "In isModifyTrailingStop: Modifying BUY Trailing Stop");             
            return true;
         }  
                
      } // end OrderStopLoss() == 0 || OrderStopLoss() > trailingStopLossLevel      
   
   } // end lOrderType == OP_SELL
 
   return false;
}

/**
  * Breaking even
  *
  * openPrice: price at which trade was placed
  * lOrderType: OP_BUY or OP_SELL
  *
  * return true if break even, false otherwise
  */
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


/**
  * Take profit
  *
  * openPrice: price at which trade was placed
  * lOrderType: OP_BUY or OP_SELL
  *
  * return true if break even, false otherwise
  */
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

// Check if isOrderClosed == false, Call GetLastError() if it is, to retreive error details
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

// clear attributes from previous setup for the new one
void resetTradeSetupAttributes() {
   
      initialTrendSetUp    =  -1;
      breakEven            =  false;
      isInLongPosition     =  false; 
      preConditionsMet     =  false;
      isInShortPosition    =  false;   
      alreadyModified      =  false;
      isMACDHistogramSell  =  false;
      isMACDHistogramBuy   =  false;
      //londonBreakOutLowestPrice = 0; 
      //londonBreakOutHighestPrice = 0;         
}

// Automatic Money Management
double GetLots() {
   double minlot = MarketInfo(SYMBOL, MODE_MINLOT);
   double maxlot = MarketInfo(SYMBOL, MODE_MAXLOT);
   double leverage = AccountLeverage();
   double lotsize = MarketInfo(SYMBOL, MODE_LOTSIZE);
   double stoplevel = MarketInfo(SYMBOL, MODE_STOPLEVEL);
   
   double minLots = 0.01; double maximalLots = 50.0;
   
   double dynamicVolume = volume;
   if (isMoneyManagementEnabled) {
              
      dynamicVolume = NormalizeDouble(AccountFreeMargin() * risk/100 / 1000.0, lotDecimalPlaces);
      if(dynamicVolume < minlot) {
         dynamicVolume = minlot;
      }
      if (dynamicVolume > maximalLots) {
         dynamicVolume = maximalLots;
      }
      if (AccountFreeMargin() < Ask * dynamicVolume * lotsize / leverage) {
         Print("We have no money. Lots = ", dynamicVolume, " , Free Margin = ", AccountFreeMargin());
         Comment("We have no money. Lots = ", dynamicVolume, " , Free Margin = ", AccountFreeMargin());
      }
   }
   else {
      dynamicVolume = NormalizeDouble(volume, Digits);
   }
      
   return(dynamicVolume);
}

double getDecimalPip() {

   //return MarketInfo(Symbol(), MODE_POINT); // Or Point
   
   switch(Digits) {
      case 3: return(0.01); //e.g. EURJPY pair
      case 4: return(0.001); //e.g. USDRZA pair
      case 5: return(0.0001); //e.g. EURUSD pair
      default: return(0.01); //e.g. SP_CrudeOil
   }
}

double getRoundedPrice(double value, int precision) {
   return( (MathCeil( value * MathPow(10, precision) - 0.5)) / (MathPow(10, precision)) );
}

int getTradeSetup() {
   
   double previousPriceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double previousPsarLevel   =  NormalizeDouble( iSAR(SYMBOL, CURRENT_TIMEFRAME, PSAR_PRICE_INCREMENT_STEP, PSAR_MAX_PRICE_INCREMENT_STEP, CURRENT_BAR), Digits);
   
   if (filterByAdx) {

      if (isAdxTrendGainingMomentum() == false) {
         
         return -1;
      }
   }     

   if (useMacDTransition) {
      if ( isMacDTransitionBuySetup() ) {
               
         tradeExecutionTime = Time[CURRENT_BAR];
         return OP_BUY;
      }
      else if ( isMacDTransitionSellSetup() ) {
         
         tradeExecutionTime = Time[CURRENT_BAR];
         return OP_SELL;
      }
   }     
   
   if (useDoubleMaCross) {
   
      if ( isStrongBuySignal(PERIOD_H1) ) {

         tradeExecutionTime = Time[CURRENT_BAR];         
         return OP_BUY;
      }
      else if ( isStrongSellSignal(PERIOD_H1) ) {

         tradeExecutionTime = Time[CURRENT_BAR];
         return OP_SELL;
      }   
   }    
   
   if (useSuperTrendCrossScalp) {
   
      if ( isSuperTrendCrossScalpBuySignal() ) {
         
         tradeExecutionTime = Time[CURRENT_BAR];
         return OP_BUY;
      }
      else if ( isSuperTrendCrossScalpSellSignal() ) {
         
         tradeExecutionTime = Time[CURRENT_BAR];
         return OP_SELL;
      }   
   }
   
   if (useMaAndPriceClose) {
   
      if ( isPriceCloseAndMaBuySignal(PERIOD_H1, phdTrendGauge) && priceCloseAndMaSignalTracker != OP_BUY ) {
      
         /*if ( isIbandMiddleBandAscending(phdTrendGauge) == false ) {
            
            return -1;
         }*/         
         
         if ( filterByLongTermTrend && ( isEmaBelowPriceLevel(longTermTrendGauge, PRICE_HIGH, false, true, (CURRENT_BAR + 1) ) ) == false ) {
            
            return -1;
         }      

         if (filterByAdxTrendDirection && (isAdxBuySignal() == false) ) {
            
            return -1;
         }
         if (filterByBollingerBands && (isPriceCloseWithinBbands(CURRENT_BAR + 1, DEFAULT_BB_PERIOD) == false) ) {
            
            return -1;
         }         
         
         tradeExecutionTime = Time[CURRENT_BAR];
         priceCloseAndMaSignalTracker = OP_BUY;
         return OP_BUY;
      }
      else if ( isPriceCloseAndMaSellSignal(PERIOD_H1, phdTrendGauge) && priceCloseAndMaSignalTracker != OP_SELL ) {
      
         /*if ( isIbandMiddleBandDescending(phdTrendGauge) == false ) {
            
            return -1;
         }*/        
      
         if ( filterByLongTermTrend && (isEmaAbovePriceLevel(longTermTrendGauge, PRICE_HIGH, false, true, (CURRENT_BAR + 1) ) ) == false ) {
            
            return -1;
         }         
      
         if (filterByAdxTrendDirection && (isAdxSellSignal() == false) ) {
            
            return -1;
         }  
         
         if (filterByBollingerBands && (isPriceCloseWithinBbands(CURRENT_BAR + 1, DEFAULT_BB_PERIOD) == false) ) {
            
            return -1;
         }                
      
         tradeExecutionTime = Time[CURRENT_BAR];
         priceCloseAndMaSignalTracker = OP_SELL;
         return OP_SELL;
      }   
   }   

   if (useCciStrategy) {
   
      if (filterByBollingerBands && ( (isPriceCloseWithinBbands(CURRENT_BAR + 1, DEFAULT_BB_PERIOD) == false) ) ) {
         
         return -1;
      }   
   
      if ( useCciStrategyStatus != OP_BUY && cciStrategyTradeExecutionTime != Time[CURRENT_BAR] ) {
      
         if ( (isCciAboveZeroLevel(50) == false) || (isCciAboveZeroLevel(200) == false) ) {
            
            return -1;
         }      
         
         if ( isCciBuy(14) ) {
            
            cciStrategyTradeExecutionTime   =  Time[CURRENT_BAR];
            
            useCciStrategyStatus =  OP_BUY;
            return OP_BUY;
         }
      }
      else if ( useCciStrategyStatus != OP_SELL && cciStrategyTradeExecutionTime != Time[CURRENT_BAR] ) {
      
         if ( (isCciBelowZeroLevel(50) == false) || (isCciBelowZeroLevel(200) == false) ) {
            
            return -1;
         }               
      
         if ( isCciSell(14) ) {      
            
            cciStrategyTradeExecutionTime   =  Time[CURRENT_BAR];
            useCciStrategyStatus =  OP_SELL;
            return OP_SELL;
         }
      }   
   }

   if (useGmma) {
   
      if ( ( ( isFastGmmaBuySignal(PERIOD_H1, CURRENT_BAR) && isSlowGmmaBuySignal(PERIOD_H1, CURRENT_BAR) ) ||
             ( isFastGmmaBuySignal(PERIOD_H1, CURRENT_BAR) && isSlowGmmaCompressed(PERIOD_H1, CURRENT_BAR) )
           )   
      && gmmaSignalTracker != OP_BUY ) {
      
         if ( isIbandMiddleBandAscending(phdTrendGauge) == false ) {
            
            return -1;
         }         
         
         if ( filterByLongTermTrend && ( isEmaBelowPriceLevel(longTermTrendGauge, PRICE_HIGH, false, true, (CURRENT_BAR + 1) ) ) == false ) {
            
            return -1;
         }      

         if (filterByAdxTrendDirection && (isAdxBuySignal() == false) ) {
            
            return -1;
         }
         if (filterByBollingerBands && (isPriceCloseWithinBbands(CURRENT_BAR + 1, DEFAULT_BB_PERIOD) == false) ) {
            
            return -1;
         }         
         
         tradeExecutionTime = Time[CURRENT_BAR];
         gmmaSignalTracker = OP_BUY;
         return OP_BUY;
      }
      else if ( ( ( isFastGmmaSellSignal(PERIOD_H1, CURRENT_BAR) && isSlowGmmaSellSignal(PERIOD_H1, CURRENT_BAR) ) ||
                  ( isFastGmmaSellSignal(PERIOD_H1, CURRENT_BAR) && isSlowGmmaCompressed(PERIOD_H1, CURRENT_BAR) ) 
                ) && gmmaSignalTracker != OP_SELL ) {
      
         if ( isIbandMiddleBandDescending(phdTrendGauge) == false ) {
            
            return -1;
         }        
      
         if ( filterByLongTermTrend && (isEmaAbovePriceLevel(longTermTrendGauge, PRICE_HIGH, false, true, (CURRENT_BAR + 1) ) ) == false ) {
            
            return -1;
         }         
      
         if (filterByAdxTrendDirection && (isAdxSellSignal() == false) ) {
            
            return -1;
         }  

         if (filterByBollingerBands && (isPriceCloseWithinBbands(CURRENT_BAR + 1, DEFAULT_BB_PERIOD) == false) ) {
            
            return -1;
         }                
      
         tradeExecutionTime = Time[CURRENT_BAR];
         gmmaSignalTracker = OP_SELL;
         return OP_SELL;
      }   
   }     
   

   if (useRsiBBStrategy) {
   
      if ( ( ( isPriceCloseBelowLowerBband(DEFAULT_BB_PERIOD, CURRENT_BAR + 1) && isRsiOverSold(CURRENT_TIMEFRAME, CURRENT_BAR + 1) ) ) 
               && rsiBBStrategySignalTracker != OP_BUY 
               && tradeExecutionTime != Time[CURRENT_BAR] // Dont buy multiple time on the same bar
               ) {
      
         tradeExecutionTime = Time[CURRENT_BAR];
         rsiBBStrategySignalTracker = OP_BUY;
         return OP_BUY;
      }
      else if ( ( ( isPriceCloseAboveUpperBband(DEFAULT_BB_PERIOD, CURRENT_BAR + 1) && isRsiOverBought(CURRENT_TIMEFRAME, CURRENT_BAR + 1) ) ) 
               && rsiBBStrategySignalTracker != OP_SELL 
               && tradeExecutionTime != Time[CURRENT_BAR] // Dont buy multiple time on the same bar               
               ) {
      
         tradeExecutionTime = Time[CURRENT_BAR];
         rsiBBStrategySignalTracker = OP_SELL;
         return OP_SELL;
      }   
   }  
   
   if (useQQE) {
   
      if ( isQQEBuy(CURRENT_BAR + 1) && QQESignalTracker != OP_BUY 
               && tradeExecutionTime != Time[CURRENT_BAR] // Dont buy multiple time on the same bar
               ) {
      
         tradeExecutionTime = Time[CURRENT_BAR];
         QQESignalTracker = OP_BUY;
         return OP_BUY;
      }
      else if ( isQQESellSetup(CURRENT_BAR + 1) && QQESignalTracker != OP_SELL 
               && tradeExecutionTime != Time[CURRENT_BAR] // Dont buy multiple time on the same bar
               ) {
      
         tradeExecutionTime = Time[CURRENT_BAR];
         QQESignalTracker = OP_SELL;
         return OP_SELL;
      }
   }
   
   if (useEnvelopes) {
   
      if ( isEnvelopesBuy(CURRENT_BAR + 1) && envelopesSignalTracker != OP_BUY 
               && tradeExecutionTime != Time[CURRENT_BAR] // Dont buy multiple time on the same bar
               && isSuperTrendBuy(CURRENT_BAR + 1)) {
      
         tradeExecutionTime = Time[CURRENT_BAR];
         envelopesSignalTracker = OP_BUY;
         return OP_BUY;
      }
      else if ( isEnvelopesSell(CURRENT_BAR + 1) && envelopesSignalTracker != OP_SELL 
               && tradeExecutionTime != Time[CURRENT_BAR] // Dont buy multiple time on the same bar
               && isSuperTrendSell(CURRENT_BAR + 1) ) {
      
         tradeExecutionTime = Time[CURRENT_BAR];
         envelopesSignalTracker = OP_SELL;
         return OP_SELL;
      }
   }           
   
   if (useLondonBreakOut) {
      
      //if ( (getLondonBreakOutBuy(londonBoSessionOpenHour) == OP_BUY) ) {
      if ( (getLondonBreakOutBuy(londonBoSessionOpenHour) == OP_BUY) && isEmaBelowPriceLevel(THREE_EMA_SLOW, PRICE_CLOSE, true, true, (CURRENT_BAR + 1) ) ) {
         
         //Print("OP_BUY!");
         return OP_BUY;
      }
      //else if ( (getLondonBreakOutSell(londonBoSessionOpenHour) == OP_SELL) ) {
      else if ( (getLondonBreakOutSell(londonBoSessionOpenHour) == OP_SELL) && isEmaAbovePriceLevel(THREE_EMA_SLOW, PRICE_CLOSE, true, true, (CURRENT_BAR + 1) ) ) {
         
         //Print("OP_SELL!");
         return OP_SELL;
      }

   }
   
   if( useShortOnLongTimeFrame) {
   
      if ( getFivenOneMaCrossBuy(PERIOD_M5, CURRENT_BAR + 1) ) {
         
         return OP_BUY;
      }
      else if ( getFivenOneMaCrossSell(PERIOD_M5, CURRENT_BAR + 1) ) {

         return OP_SELL;
      }    
   
   }
   
   if (useDoubleMaCrossRetracement) {
      if ( isDoubleMaCrossBuyRetracement(PERIOD_H1, THREE_EMA_MEDIUM, THREE_EMA_SLOW) && isMACDHistogramAboveZero() ) {
         return OP_BUY;
      }
      else if ( isDoubleMaCrossSellRetracement(PERIOD_H1) && isMACDHistogramBelowZero()) {
         return OP_SELL;
      }   
   }
   
   if (use5MDoubleMaCross) {
      if ( isFastMaAboveSlowMa(PERIOD_H1, THREE_EMA_MEDIUM, THREE_EMA_SLOW, true, CURRENT_BAR) && isStrongBuySignal(PERIOD_M5) ) {
         return OP_BUY;
      }
      else if ( isSlowMaAboveFastMa(PERIOD_H1, THREE_EMA_MEDIUM, THREE_EMA_SLOW, true, CURRENT_BAR) && isStrongSellSignal(PERIOD_M5) ) {
         return OP_SELL;
      }   
   }     
   
   if (usePriceAndEma) {
   
      //Any time the price goes above or below THREE_EMA_MEDIUM and THREE_EMA_SLOW, and THREE_EMA_MEDIUM is is above/below THREE_EMA_SLOW, 
      //not caring wether the previous was above/below, just crossed, etc.
      int conditionOnBarIndex = CURRENT_BAR + 1;
      if ( 
            isFastMaAboveSlowMa(PERIOD_H1, THREE_EMA_MEDIUM, THREE_EMA_SLOW, true, conditionOnBarIndex) && 
            isEmaBelowPriceLevel(THREE_EMA_MEDIUM, PRICE_CLOSE, true, true, conditionOnBarIndex ) 
            && isEmaBelowPriceLevel(THREE_EMA_SLOW, PRICE_CLOSE, true, true, conditionOnBarIndex ) 
            && previousTrade != OP_BUY
            
            && tradeExecutionTime != Time[conditionOnBarIndex] // Dont buy multiple time on the same bar
         ) 
      {

         tradeExecutionTime = Time[conditionOnBarIndex];
         previousTrade = OP_BUY;
         return OP_BUY;
         
         
      }
      else if ( 
                  isSlowMaAboveFastMa(PERIOD_H1, THREE_EMA_MEDIUM, THREE_EMA_SLOW, true, conditionOnBarIndex) && 
                  isEmaAbovePriceLevel(THREE_EMA_MEDIUM, PRICE_CLOSE, true, true, conditionOnBarIndex) 
                  && isEmaAbovePriceLevel(THREE_EMA_SLOW, PRICE_CLOSE, true, true, conditionOnBarIndex) 
                  && previousTrade != OP_SELL
                  
                  && tradeExecutionTime != Time[conditionOnBarIndex] // Dont buy multiple time on the same bar
              ) 
     {
      
         tradeExecutionTime = Time[conditionOnBarIndex];
         
         previousTrade = OP_SELL;
         return OP_SELL;
         
     }
   }
   
   // if not a BUY nor SELL, return NO(No Operation)
   return -1;
}
/** SETUP */

/**---STRATEGIES----*/

/**---QQE STRATEGY----------*/
bool isQQEBuySetup(int barIndex) {
   
   return isQQEBuy(barIndex);
}   

bool isQQESellSetup(int barIndex) {
   
   return isQQESell(barIndex);
} 
/**---QQE STRATEGY----------*/

/** ENVELOPES */
bool isEnvelopesBuySetup(int barIndex) {
   
   return isEnvelopesBuy(barIndex);
}   

bool isEnvelopesBuySellSetup(int barIndex) {
   
   return isEnvelopesSell(barIndex);
} 
/** ENVELOPES */

/** MACD TRANSITION STRATEGY*/
bool isMacDTransitionBuySetup() {

   double previousPriceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double previousPsarLevel   =  NormalizeDouble( iSAR(SYMBOL, CURRENT_TIMEFRAME, PSAR_PRICE_INCREMENT_STEP, PSAR_MAX_PRICE_INCREMENT_STEP, CURRENT_BAR), Digits);
      
   if( isMACDHistogramBuy() == false ) {
      return false;
   }
   
   if( (isFilteredNoiseByDamianiVolatmeterV0() == false) ) {
      return false;
   }
   
   /*if( (isFilteredNoiseByDamianiVolatmeterV32() == false) ) {
      return false;
   }   */
   
   if( (previousPriceClose > previousPsarLevel) == false ) {
      return false;
   }
   
   if ( filterByLongTermTrend && (isEmaBelowPriceLevel(longTermTrendGauge, PRICE_CLOSE, true, true, (CURRENT_BAR + 1) ) ) == false ) {
      return false;
   }
   
   if ( isPriceNested() == true ) {
      return false;
   }
   
   if ( isChikouSpanAbovePriceClose() == false ) {
      return false;
   } 
   
   if ( isRsiOverBought(rsiExtremeConditionsTimeFrame, CURRENT_BAR) == true ) {
      return false;
   } 
   
   return true;                                                                         

}

bool isMacDTransitionSellSetup() {
   
   double previousPriceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double previousPsarLevel   =  NormalizeDouble( iSAR(SYMBOL, CURRENT_TIMEFRAME, PSAR_PRICE_INCREMENT_STEP, PSAR_MAX_PRICE_INCREMENT_STEP, CURRENT_BAR), Digits);
   
   if( isMACDHistogramSell() == false ) {
      return false;
   }
   
   if( (isFilteredNoiseByDamianiVolatmeterV0() == false) ) {
      return false;
   }
   
   /*if( (isFilteredNoiseByDamianiVolatmeterV32() == false) ) {
      return false;
   }   */   
   
   if( (previousPriceClose < previousPsarLevel) == false ) {
      return false;
   }
   
   if ( filterByLongTermTrend && isEmaAbovePriceLevel(longTermTrendGauge, PRICE_CLOSE, true, true, (CURRENT_BAR + 1) ) == false ) {
      return false;
   }
   
   if ( isPriceNested() == true ) {
      return false;
   }
   
   if ( isChikouSpanBelowPriceClose() == false ) {
      return false;
   } 
   
   if ( isRsiOverSold(rsiExtremeConditionsTimeFrame, CURRENT_BAR) == true ) {
      return false;
   }    

   return true;

}
/** MACD TRANSITION STRATEGY*/

/** DOUBLE MA CROSS STRATEGY*/
bool isStrongBuySignal(ENUM_TIMEFRAMES timeFrame) {
   
   //Long Term Trend - 1D
   
   //Check Medium Term - 1 or 4H
   /* Repeat 1 - 3 */   
   /*4. Check Fast and Medium MA crossing*/
   
   if (timeFrame != PERIOD_D1) {
      
      if( (isMaCrossStrongBuy(THREE_EMA_MEDIUM, THREE_EMA_SLOW, CURRENT_BAR, timeFrame) == OP_BUY) == false ) {
         return false;
      }
   }
      
   return true;
   
} 

bool isStrongSellSignal(ENUM_TIMEFRAMES timeFrame) {
   
   
   //Long Term Trend - 1D
   
   //Check Medium Term - 1 or 4H
   /* Repeat 1 - 3 */   
   /*4. Check Fast and Medium MA crossing*/
   
   if (timeFrame != PERIOD_D1) {
      
      if( (isMaCrossStrongSell(THREE_EMA_MEDIUM, THREE_EMA_SLOW, CURRENT_BAR, timeFrame) == OP_SELL) == false ) {
         return false;
      }
   }
      
   return true; 
   
}
/** DOUBLE MA CROSS STRATEGY*/
 
/** SUPERSCALP STRATEGY*/
bool isSuperTrendCrossScalpBuySignal() {

   if (superTrendCrossScalpBuyTime != Time[CURRENT_BAR]) {

      if( isPriceCloseAboveMiddleBand(100) == false) {
         
         return false;
      }
      
      if( isPriceCloseAboveMiddleBand(55) == false) {

         return false;
      } 
      
      if( isPriceCloseAboveMiddleBand(34) == false) {
         
         return false;
      }  
      
      if( isPriceCloseAboveMiddleBand(14) == false) {
         
         return false;
      } 

      if( isPriceCloseAboveMiddleBand(9) == false) {
         
         return false;
      }                        
      
      if ( isFastMaAboveSlowMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, 14, true, CURRENT_BAR ) == false ) {
         
         return false;
      }       
      
      if ( (isFastMaAboveSlowMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR + 1) == false ) 
         && isFastMaAboveSlowMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR ) == true ) {
         
         superTrendCrossScalpBuyTime = Time[CURRENT_BAR];
         return true;
      }    
      
      //TODO: Add or if the fast MAs has crossed few bars back already and the previous bar only just close above last(to make All MAs)      
   }   
   
   return false;
} 

bool isSuperTrendCrossScalpSellSignal() {
  
   if (superTrendCrossScalpSellTime != Time[CURRENT_BAR]) {

      if( isPriceCloseBelowMiddleBand(100) == false) {
         
         return false;
      }
      
      if( isPriceCloseBelowMiddleBand(55) == false) {
         
         return false;
      }      
      
      if( isPriceCloseBelowMiddleBand(34) == false) {
         
         return false;
      }   
      
      if( isPriceCloseBelowMiddleBand(14) == false) {
         
         return false;
      }     
      
      if( isPriceCloseBelowMiddleBand(9) == false) {
         
         return false;
      }                  
      
      if ( isSlowMaAboveFastMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, 14, true, CURRENT_BAR ) == false ) {
         
         return false;
      }        
      
      if ( (isSlowMaAboveFastMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR + 1) == false ) 
         && (isSlowMaAboveFastMa(PERIOD_H1, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR) == true ) ) {
         
         superTrendCrossScalpSellTime = Time[CURRENT_BAR];
         return true;
      }  
      
      //TODO: Add or if the fast MAs has crossed few bars back already and the previous bar only just close below last(to make All MAs)
   }   

   return false; 
   
}
/** SUPERSCALP STRATEGY*/


/** PRICE ACTION AND MA STRATEGY*/
bool isPriceCloseAndMaBuySignal(ENUM_TIMEFRAMES timeframe, int period) {

   if ( (isFastMaAboveSlowMa(timeframe, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR + 1 ) == false) && 
         (isFastMaAboveSlowMa(timeframe, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR ) == false)) {
      
      return false;
   }

   if (superTrendCrossScalpBuyTime != Time[CURRENT_BAR]) {

      if ( isPriceCloseAboveMiddleBand(period) == true ) {
         
         superTrendCrossScalpBuyTime = Time[CURRENT_BAR];
         return true;
      }    
   }   
   
   return false;
} 

bool isPriceCloseAndMaSellSignal(ENUM_TIMEFRAMES timeframe, int period) {

   if ( (isSlowMaAboveFastMa(timeframe, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR + 1 ) == false ) &&
         (isSlowMaAboveFastMa(timeframe, SUPER_TREND_CROSS_SCALP_SUPER_FAST_MA, SUPER_TREND_CROSS_SCALP_FAST_MA, true, CURRENT_BAR ) == false ) ) {
      
      return false;
   }

   if (superTrendCrossScalpSellTime != Time[CURRENT_BAR]) {

      if ( isPriceCloseBelowMiddleBand(period) == true ) {
      
         superTrendCrossScalpSellTime = Time[CURRENT_BAR];
         return true;
      }  

   }   

   return false; 
   
}
/** PRICE ACTION AND MA STRATEGY*/

/** Guppy Multiple Moving Average(GMMA) AND MA STRATEGY*/

bool isFastGmmaBuySignal(ENUM_TIMEFRAMES timeframe, int barIndex) {

   /** Fast MAs */
   int maThree = 3, maFive = 5, maEight = 8, maTen = 10, maTwelve = 12, maFifteen = 15;

   if ( (isFastMaAboveSlowMa(timeframe, maThree, maFive, false, barIndex ) == false) ) {
      
      return false;
   }

   if ( (isFastMaAboveSlowMa(timeframe, maFive, maEight, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maEight, maTen, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maTen, maTwelve, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maTwelve, maFifteen, false, barIndex ) == false) ){
      
      return false;
   }           
   
   /* It's a match!!!*/
   return true;
} 

bool isSlowGmmaBuySignal(ENUM_TIMEFRAMES timeframe, int barIndex) {

   int maThirty = 30, maThirtyFive = 35, maFourty = 40, maFourtyFive = 45, maFifty= 50, maSixty = 60;

   if ( (isFastMaAboveSlowMa(timeframe, maThirty, maThirtyFive, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maThirtyFive, maFourty, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maFourty, maFourtyFive, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maFourtyFive, maFifty, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isFastMaAboveSlowMa(timeframe, maFifty, maSixty, false, barIndex ) == false) ){
      
      return false;
   }  
   
   /* It's a match!!!*/
   return true;
} 


bool isFastGmmaCompressed(ENUM_TIMEFRAMES timeframe, int barIndex) {

   double maThreeLevel        =  getMovingAverageLevel(3, CURRENT_BAR);
   double maThreeRoundedLevel =  getRoundedPrice(maThreeLevel, gmmaRoundingPrecision);
   
   double maFiveLevel         =  getMovingAverageLevel(5, CURRENT_BAR);
   double maFiveRoundedLevel  =  getRoundedPrice(maFiveLevel, gmmaRoundingPrecision);

   double maEightLevel        =  getMovingAverageLevel(8, CURRENT_BAR);
   double maEightRoundedLevel =  getRoundedPrice(maEightLevel, gmmaRoundingPrecision);
   
   double maTenLevel          =  getMovingAverageLevel(10, CURRENT_BAR);
   double maTenRoundedLevel   =  getRoundedPrice(maTenLevel, gmmaRoundingPrecision);
    
   double maTwelveLevel          =  getMovingAverageLevel(12, CURRENT_BAR);
   double maTwelveRoundedLevel   =  getRoundedPrice(maTwelveLevel, gmmaRoundingPrecision);      

   double maFifteenLevel         =  getMovingAverageLevel(15, CURRENT_BAR);
   double maFifteenRoundedLevel  =  getRoundedPrice(maFifteenLevel, gmmaRoundingPrecision); 

   if ( (maThreeRoundedLevel == maThreeRoundedLevel) == false) {
      
      return false;
   }

   if ( (maThreeRoundedLevel == maEightRoundedLevel) == false) {
      
      return false;
   }
   
   if ( (maEightRoundedLevel == maTenRoundedLevel) == false) {
      
      return false;
   }
   
   if ( (maTenRoundedLevel == maTwelveRoundedLevel) == false) {
      
      return false;
   }
   
   if ( (maTwelveRoundedLevel == maFifteenRoundedLevel) == false) {
      
      return false;
   }           
   
   Print(maTwelveRoundedLevel);
   
   /* It's a match!!!*/
   return true;
} 

bool isSlowGmmaCompressed(ENUM_TIMEFRAMES timeframe, int barIndex) {

   double maThirtyLevel          =  getMovingAverageLevel(30, CURRENT_BAR);
   double maThirtyRoundedLevel   =  getRoundedPrice(maThirtyLevel, gmmaRoundingPrecision);
   
   double maThirtyFiveLevel         =  getMovingAverageLevel(35, CURRENT_BAR);
   double maThirtyFiveRoundedLevel  =  getRoundedPrice(maThirtyFiveLevel, gmmaRoundingPrecision);

   double maFourtyLevel          =  getMovingAverageLevel(40, CURRENT_BAR);
   double maFourtyRoundedLevel   =  getRoundedPrice(maFourtyLevel, gmmaRoundingPrecision);
   
   double maFourtyFiveLevel         =  getMovingAverageLevel(45, CURRENT_BAR);
   double maFourtyFiveRoundedLevel  =  getRoundedPrice(maFourtyFiveLevel, gmmaRoundingPrecision);
    
   double maFiftyLevel        =  getMovingAverageLevel(50, CURRENT_BAR);
   double maFiftyRoundedLevel =  getRoundedPrice(maFiftyLevel, gmmaRoundingPrecision);      

   double maSixtyLevel        =  getMovingAverageLevel(60, CURRENT_BAR);
   double maSixtyRoundedLevel =  getRoundedPrice(maSixtyLevel, gmmaRoundingPrecision); 

   if ( (maThirtyRoundedLevel == maThirtyFiveRoundedLevel) == false) {
      
      return false;
   }

   if ( (maThirtyRoundedLevel == maFourtyRoundedLevel) == false) {
      
      return false;
   }
   
   if ( (maFourtyRoundedLevel == maFourtyFiveRoundedLevel) == false) {
      
      return false;
   }
   
   if ( (maFourtyFiveRoundedLevel == maFiftyRoundedLevel) == false) {
      
      return false;
   }
   
   if ( (maFiftyRoundedLevel == maSixtyRoundedLevel) == false) {
      
      return false;
   }           
   
   /* It's a match!!!*/
   return true;
} 

bool isFastGmmaSellSignal(ENUM_TIMEFRAMES timeframe, int barIndex) {

   int maThree = 3, maFive = 5, maEight = 8, maTen = 10, maTwelve = 12, maFifteen = 15;

   if ( (isSlowMaAboveFastMa(timeframe, maThree, maFive, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maFive, maEight, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maEight, maTen, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maTen, maTwelve, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maTwelve, maFifteen, false, barIndex ) == false) ){
      
      return false;
   }            

   /* It's a match!!!*/
   return true;
}

bool isSlowGmmaSellSignal(ENUM_TIMEFRAMES timeframe, int barIndex) {

   int maThirty = 30, maThirtyFive = 35, maFourty = 40, maFourtyFive = 45, maFifty= 50, maSixty = 60;

   if ( (isSlowMaAboveFastMa(timeframe, maThirty, maThirtyFive, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maThirtyFive, maFourty, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maFourty, maFourtyFive, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maFourtyFive, maFifty, false, barIndex ) == false) ){
      
      return false;
   }
   
   if ( (isSlowMaAboveFastMa(timeframe, maFifty, maSixty, false, barIndex ) == false) ){
      
      return false;
   }  
   
   return true;
}
/** Guppy Multiple Moving Average(GMMA) AND MA STRATEGY*/
/**---END STRATEGIES----*/


/**QQE */
bool isQQEBuy(int barIndex) {
  
   double upTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_QQE_v1", 0, barIndex), Digits); //Green line
   double downTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_QQE_v1", 1, barIndex), Digits); //Red Line
   
   return (upTrendLevel > downTrendLevel);
}

bool isQQESell(int barIndex) {
  
   double upTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_QQE_v1", 0, barIndex), Digits); //Green line
   double downTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_QQE_v1", 1, barIndex), Digits); //Red Line
   
   return (downTrendLevel > upTrendLevel);
}
/**QQE */

/**Super Trend */
bool isSuperTrendBuy(int barIndex) {
  
   double superTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_Super_Trend", 0, CURRENT_BAR), Digits);  //Green line
   
   return (superTrendLevel != EMPTY_VALUE);
}

bool isSuperTrendSell(int barIndex) {
  
   double downTrendLevel = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_Super_Trend", 1, CURRENT_BAR), Digits); //Red Line
   
   return (downTrendLevel != EMPTY_VALUE);
}
/**Super Trend */

/**ENVELOPES */
bool isEnvelopesBuy(int barIndex) {
  
   double envelopUpperLevel = NormalizeDouble(iEnvelopes(NULL, 0, 14, MODE_LWMA, 0 , PRICE_CLOSE, 0.1, MODE_UPPER, barIndex), Digits);
 
   return ( (iClose(Symbol(), Period(), barIndex)) > envelopUpperLevel);
}

bool isEnvelopesSell(int barIndex) {
  
double envelopLowerLevel = NormalizeDouble(iEnvelopes(NULL, 0, 14, MODE_LWMA, 0 , PRICE_CLOSE, 0.1, MODE_UPPER, barIndex), Digits);
   
   return ( (iClose(Symbol(), Period(), CURRENT_BAR + 1) ) < envelopLowerLevel);
}
/**ENVELOPES */

/**---MISCELLANEOUS----*/
void testQQE() {
   
   
   /*
   double value = NormalizeDouble(iCustom(Symbol(), Period(), "QQE_Alert_MTF_v5", 5, 0, false, false, false, false, false, false, 
   "", "", "", "", "", "", 
   "alert.wav", "alert.wav", "alert.wav", "alert.wav", "alert.wav", "alert.wav", 
   false, false, false, false, false, false,
   "DodgerBlue", "Crimson", "Teal", "Pink", "Blue", "Red", 
   10,
   1,//value
   CURRENT_BAR), Digits); */
   
   double freescalpingindicatorLevel = NormalizeDouble(iCustom(Symbol(), Period(), "freescalpingindicator", 18, 800, 0, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   Print("Level =>" + freescalpingindicatorLevel);return;
   
   double Value1 = NormalizeDouble(iCustom(Symbol(), Period(), "freescalperindicatorJanus", 14, 0, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   double Value2 = NormalizeDouble(iCustom(Symbol(), Period(), "freescalperindicatorJanus", 14, 1, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   if ( Value1 == 0.2 && Value2 == 0) {
   
      Print("UP TRENDS");
   }
   else if ( Value2 == 0.2 && Value1 == 0) {
      Print("DOWN TRENDS");
   }      
   return;
   
   double upTrendStop = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_BBand_Stop", 0, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   double upTrendSignal = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_BBand_Stop", 2, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   double upTrendLine = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_BBand_Stop", 4, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   
   
   double downTrendStop = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_BBand_Stop", 1, CURRENT_BAR), Digits); //Continues until the trend is exhausted
   double downTrendSignal = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_BBand_Stop", 3, CURRENT_BAR), Digits); // Only true on first downtrend tick
   double downTrendLine = NormalizeDouble(iCustom(Symbol(), Period(), "PhD_BBand_Stop", 5, CURRENT_BAR), Digits);//Continues until the trend is exhausted
    
   if ( upTrendStop != -1 && upTrendLine != EMPTY_VALUE) {
   
      Print("UP TRENDS");
   }
   else  if ( downTrendStop != -1 && downTrendLine != EMPTY_VALUE) {
   
      Print("DOWN TRENDS");
   }   
   
   /*
   //if ( upTrendStop != -1 && upTrendLine != -1) {
   if ( upTrendStop != -1 && upTrendSignal != -1) {
   
      Print("UP TRENDS");
   }
   //else  if ( downTrendStop != -1 && downTrendLine != -1) {
   else if ( downTrendStop != -1 && downTrendSignal != -1) {
   
      Print("DOWN TRENDS");
   } */   
   
  
}

void testUltraSignal() {

   //Implement PhD HuppyNoLagEnv Strategy
   //Look how far it the price relative to the SnR - if close to the R: only buy, if close to R: only sell. Dont trade within envelopes, trade the breakout(in the 
   // direction on the SnR, Guppy, NOLag, etc)

   //SMI + NoLag + RSI + BB(Middle band) NoLag closes above/below middle band
   double smiVaule = NormalizeDouble(iCustom(Symbol(), Period(), "SMI", 2, 8, 5, 5, CURRENT_BAR), Digits); 
   Print("SMI" + smiVaule);
   
   //NonLag v7.1
   double nonLag7_1 = NormalizeDouble(iCustom(Symbol(), Period(), "NonLagMA_v7.1", 0, CURRENT_BAR), Digits); 
   double upNonLag7_1_up = NormalizeDouble(iCustom(Symbol(), Period(), "NonLagMA_v7.1", 1, CURRENT_BAR), Digits); 
   double downNonLag7_1_down = NormalizeDouble(iCustom(Symbol(), Period(), "NonLagMA_v7.1", 2, CURRENT_BAR), Digits); 
   Print("NonLag7_1" + nonLag7_1);
   Print("NonLag7_1: UP" + upNonLag7_1_up);
   Print("NonLag7_1: DOWN" + downNonLag7_1_down);

   //arrows
   double dblICustom0 = NormalizeDouble(iCustom(Symbol(), Period(), "FDM Entry Arrows with Alerts",FALSE,0, CURRENT_BAR), Digits); 
   double dblICustom1 = NormalizeDouble(iCustom(Symbol(), Period(), "FDM Entry Arrows with Alerts",FALSE,1, CURRENT_BAR), Digits); 
  
   //SnR    
   double dblResistenza   = NormalizeDouble(iCustom(Symbol(), Period(), "FDM Support and Resistance",0, 0), Digits); 
   double dblSupporto     = NormalizeDouble(iCustom(Symbol(), Period(), "FDM Support and Resistance",1, 0), Digits); 

   //trend
   double TDM  =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "FDM Real Price", 2, CURRENT_BAR), Digits); 

   double value  =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "ultra_signal_2_0", 0, CURRENT_BAR), Digits); 
   double value1  =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "ultra_signal_2_0", 1, CURRENT_BAR), Digits); 
   double value2  =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "ultra_signal_2_0", 2, CURRENT_BAR), Digits); 
  
   if ( value1 == 2147483647) {
   
      Print("DownTrend");
   }
   else  if ( value == 2147483647) {
   
      Print("UpTrend");
   }

}


/** MOVING AVERAGES */
double getMovingAverageLevel(int emaPeriod, int barIndex) {
  
   return NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits);
}

bool isDoubleMaCrossBuyRetracement(ENUM_TIMEFRAMES timeFrame, int threeEmaMedium, int threeEmaSlow) {
   
   if (isFastMaAboveSlowMa(timeFrame, threeEmaMedium, threeEmaSlow, true, CURRENT_BAR) == false ) {
      
      return false;
   } 

   double thirdPreviousMaLevel      =  iMA(SYMBOL, timeFrame, threeEmaSlow, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR + 3);  
   double thirdPreviousPriceClose   =  iClose(SYMBOL, timeFrame, CURRENT_BAR + 3); 
   if ( (thirdPreviousMaLevel > thirdPreviousPriceClose) == false) {

      return false;
   }

   double secondPreviousMaLevel     =  iMA(SYMBOL, timeFrame, threeEmaSlow, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR + 2);  
   double secondPreviousPriceClose  =  iClose(SYMBOL, timeFrame, CURRENT_BAR + 2);
   if ( (secondPreviousMaLevel > secondPreviousPriceClose) == false) {
      return false;
   }

   double previousMaLevel     =  iMA(SYMBOL, timeFrame, threeEmaSlow, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR + 1);
   double previousPriceClose  =  iClose(SYMBOL, timeFrame, CURRENT_BAR + 1);
   if ( (previousMaLevel < previousPriceClose) == false) {
      return false;
   }

   double currentMaLevel   =  iMA(SYMBOL, timeFrame, threeEmaSlow, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR);  
   double currentPriceHigh =  iClose(SYMBOL, timeFrame, CURRENT_BAR);
   if ( (currentMaLevel < currentPriceHigh) == false) {
      return false;
   }

   if ( (currentPriceHigh > previousPriceClose) == false) {
      return false;
   }
   
   return true;  
} 

bool isDoubleMaCrossSellRetracement(ENUM_TIMEFRAMES timeFrame) {
      
   //Long Term Trend - 1D
   
   //Check Medium Term - 1 or 4H
   /* Repeat 1 - 3 */   
   /*4. Check Fast and Medium MA crossing*/
   
   if (timeFrame != PERIOD_D1) {
      
      if( (isMaCrossStrongSell(THREE_EMA_MEDIUM, THREE_EMA_SLOW, CURRENT_BAR, timeFrame) == OP_SELL) == false ) {
         return false;
      }
   }
      
   return true;    
}

bool isEmaBelowCurrentBullishBar(int emaPeriod) {

   double emaLevel   =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, CURRENT_BAR), Digits);
   double priceOpen  =  iOpen(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double priceHigh  =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double priceClose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);

   /*if( priceOpen > emaLevel) {
      Print("priceOpen > emaLevel: " );
   }
   if(priceHigh > priceOpen) {
      Print("priceHigh > priceOpen: " );
   }*/
   
   return priceOpen > emaLevel && 
   
           //it must go down from open atleast once   
          priceHigh > priceOpen;          
}

bool isEmaBelowPriceLevel(int emaPeriod, ENUM_APPLIED_PRICE lLppliedPrice, bool applyAscendingMaFilter, bool applyBullishBarFilter, int lBarIndex) {

   if ( applyAscendingMaFilter ) {
   
      double currentMaLevel   =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, lLppliedPrice, CURRENT_BAR), Digits);  
      double previousMaLevel  =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, lLppliedPrice, CURRENT_BAR + 1), Digits);     
      // MA must be ascending
      if( (currentMaLevel > previousMaLevel) == false ) {
         
         return false;
      } 
   }
   
   double priceOpen  =  iOpen(SYMBOL, CURRENT_TIMEFRAME, lBarIndex);
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, lBarIndex);
   
   // Bullish bar and higher than EMA level
   if( applyBullishBarFilter && ( (priceClose > priceOpen) == false) ) {
      
      return false;
   }
   
   // Higher than EMA level   
   double emaLevel   =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, lLppliedPrice, lBarIndex), Digits);  
   return (priceClose > emaLevel);
}

bool isEmaAbovePriceLevel(int emaPeriod, ENUM_APPLIED_PRICE lLppliedPrice, bool applyDescendingMaFilter, bool applyBearishBarFilter, int lBarIndex) {
 
   if ( applyDescendingMaFilter ) { 
      
      double currentMaLevel   =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, lLppliedPrice, CURRENT_BAR), Digits);  
      double previousMaLevel  =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, lLppliedPrice, CURRENT_BAR + 1), Digits);     
      
      // MA must be descending
      if( (currentMaLevel < previousMaLevel) == false ) {
         
         return false;
      } 
   }
   
   double priceOpen  =  iOpen(SYMBOL, CURRENT_TIMEFRAME, lBarIndex);
   double priceClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, lBarIndex);
   if( applyBearishBarFilter && ( (priceClose < priceOpen) == false ) ) {
      
      return false;
   }

   double emaLevel   =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, lLppliedPrice, lBarIndex), Digits); 
   return (priceClose < emaLevel);
}

bool isEmaAboveCurrentBearishBar(int emaPeriod) {
 
   double priceOpen  =  iOpen(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double priceLow   =  iLow(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   double emaLevel   =  NormalizeDouble( iMA(SYMBOL, CURRENT_TIMEFRAME, emaPeriod, MA_SHIFT, MA_METHOD, emaPeriod, CURRENT_BAR), Digits);
   
   return (/*priceHigh < emaLevel) &&  
           (priceHigh < priceOpen) //&& //?*/
           priceOpen < emaLevel) &&  
           
           //it must go down from open atleast once
          (priceLow < priceOpen);
}

int getFivenOneMaCrossBuy(ENUM_TIMEFRAMES timeframe, int lBarIndex) {

   if (fivenOneMaCrossTime != Time[CURRENT_BAR]) {

      if(isEmaBelowPriceLevel(THREE_EMA_SLOW, PRICE_CLOSE, true, true, lBarIndex) == true) {
         
         return -1;
      }
      
      if ( isStrongBuySignal(timeframe) ) {
         
         fivenOneMaCrossTime = Time[CURRENT_BAR];
         return OP_BUY;
      }   

   }
   
   return -1;   
}

int getFivenOneMaCrossSell(ENUM_TIMEFRAMES timeframe, int lBarIndex) {

   if (fivenOneMaCrossTime != Time[CURRENT_BAR]) {

      if(isEmaAbovePriceLevel(THREE_EMA_SLOW, PRICE_CLOSE, true, true, lBarIndex) == true) {
         
         return -1;
      }  
      
      if ( isStrongSellSignal(timeframe) ) {
         
         fivenOneMaCrossTime = Time[CURRENT_BAR];
         return OP_SELL;
      }       
   
   }
   
   return -1;
}

int isTrippleMAIntersectionOnCoupleOfBarsBuy(int fastMaPeriod, int mediumMaPeriod, int slowMaPeriod, ENUM_TIMEFRAMES timeframe) {
   
   int OPERATION = -1;
   
   //Fast MAs
   for (int barIndex = 0; barIndex < trippleMAIntersectionBarsToProcess; barIndex++) {

      if (fastMAIntersectionTime != Time[barIndex]) {
   
         if ( (isMaCrossStrongBuy(fastMaPeriod, mediumMaPeriod, barIndex, timeframe) == OP_BUY) == false) {
            
            continue;
         }
      
         fastMAIntersectionTime = Time[barIndex];
         OPERATION = OP_BUY;
         
         break;
      } 
   
   }
   
   if ( OPERATION == OP_BUY ) {
    
      //Slow MAs 
      OPERATION = -1;                // Clear operation to be used in second MA pair
      for (int barIndex = 0; barIndex < trippleMAIntersectionBarsToProcess; barIndex++) {
   
         if (slowMAIntersectionTime != Time[barIndex]) {
            
            if ( (isMaCrossStrongBuy(mediumMaPeriod, slowMaPeriod, barIndex, timeframe) == OP_BUY) == false) {
               
               continue;
            }
            
            Print("Deal");
            slowMAIntersectionTime = Time[barIndex];
            OPERATION = OP_BUY;
            
            break;
         } 
      
      }   
   }
     
   return OPERATION;
}

int isTrippleMAIntersectionOnCoupleOfBarsSell(int fastMaPeriod, int mediumMaPeriod, int slowMaPeriod, ENUM_TIMEFRAMES timeframe) {
   
   int OPERATION = -1;
   
   //Fast MAs
   for (int barIndex = 0; barIndex < trippleMAIntersectionBarsToProcess; barIndex++) {

      if (trippleMAIntersectionTime != Time[barIndex]) {
   
         if ( (isMaCrossStrongBuy(fastMaPeriod, mediumMaPeriod, barIndex, timeframe) == OP_SELL) == false) {
            
            continue;
         }
      
         trippleMAIntersectionTime = Time[barIndex];
         OPERATION = OP_SELL;
         break;
      } 
   
   }
   
   if ( OPERATION == OP_SELL ) {
      
      Print("OPERATION == OP_SELL");
      
      //Slow MAs 
      OPERATION = -1;                // Clear operation to be used in second MA pair      
      for (int barIndex = 0; barIndex < trippleMAIntersectionBarsToProcess; barIndex++) {
   
         if (fastMAIntersectionTime != Time[barIndex]) {
      
            if ( (isMaCrossStrongBuy(mediumMaPeriod, slowMaPeriod, barIndex, timeframe) == OP_SELL) == false) {
               
               continue;
            }
            
            fastMAIntersectionTime = Time[barIndex];
            OPERATION = OP_SELL;
            break;
         } 
      
      }   
   }     
   
   return OPERATION;
}

int isTrippleMAIntersectionBuy(int fastMaPeriod, int mediumMaPeriod, int slowMaPeriod, ENUM_TIMEFRAMES timeframe) {
   
   int NO_OP = -1;
   
   if (slowMAIntersectionTime != Time[CURRENT_BAR]) {

      if ( (isMaCrossStrongBuy(fastMaPeriod, mediumMaPeriod, CURRENT_BAR, timeframe) == OP_BUY) == false) {
         
         return NO_OP;
      }
   
      if ( (isMaCrossStrongBuy(mediumMaPeriod, slowMaPeriod, CURRENT_BAR, timeframe) == OP_BUY) == false) {
         
         return NO_OP;
      }
      
      slowMAIntersectionTime = Time[CURRENT_BAR];
      return OP_BUY;
   }  
   
   return NO_OP;
}

int isTrippleIntersectionMASell(int fastMaPeriod, int mediumMaPeriod, int slowMaPeriod, ENUM_TIMEFRAMES timeframe) {
   
   int NO_OP = -1;
   
   if (trippleMAIntersectionTime != Time[CURRENT_BAR]) {
   
      if ( (isMaCrossStrongSell(fastMaPeriod, mediumMaPeriod, CURRENT_BAR, timeframe) == OP_SELL) == false) {
         
         return NO_OP;
      }
   
      if ( (isMaCrossStrongSell(mediumMaPeriod, slowMaPeriod, CURRENT_BAR, timeframe) == OP_SELL) == false) {
         
         return NO_OP;
      }
      
      trippleMAIntersectionTime = Time[CURRENT_BAR];
      return OP_SELL;   
   }
   
   return NO_OP;   
}

int isMaCrossStrongBuy(int fastMaPeriod, int slowMaPeriod, int barIndex, ENUM_TIMEFRAMES timeframe) {
 
   int NO_OP = -1;

   if (slowMACrossTime != Time[barIndex]) {
      
      double currentFastMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
      double currentSlowMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
      
      double previousFastMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
      double previousSlowMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
      
      double previousPreviousFastMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 2), Digits); 
      double previousPreviousSlowMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 2), Digits); 
      
      if ( (previousPreviousSlowMaLevel > previousPreviousFastMaLevel) == false) { 
         
         // Should have been greater- if slow was already below, then this was already buy setup
         return NO_OP;
      } 
      
      if ( (previousFastMaLevel > previousSlowMaLevel) == false) { 
      
         // Should have been greater
         return NO_OP;
      }
      
      if ( (currentFastMaLevel > currentSlowMaLevel) == false ) { 
      
         // Should have been greater
         return NO_OP;
      }
      
      slowMACrossTime = Time[barIndex];
      
      // At this point, index bar 2 is sell, index bar 1 changed to buy, current(index bar 0) bar is buy. 
      // And a new bar formed
      return OP_BUY;
   }
   
   return NO_OP;
}

int isMaCrossStrongSell(int fastMaPeriod, int slowMaPeriod, int barIndex, ENUM_TIMEFRAMES timeframe) {
 
   int NO_OP = -1;

   if (slowMACrossTime != Time[barIndex]) {
      
      double currentFastMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
      double currentSlowMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
      
      double previousFastMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
      double previousSlowMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
      
      double previousPreviousFastMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 2), Digits); 
      double previousPreviousSlowMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 2), Digits); 
      
      if ( (previousPreviousFastMaLevel > previousPreviousSlowMaLevel) == false ) {
         
         // Should have been greater - if fast was already below, then this was already sell setup
         return NO_OP;
      } 
      if ( (previousSlowMaLevel > previousFastMaLevel) == false ) { 
      
         // Should have been greater
         return NO_OP;
      }
      if ( (currentSlowMaLevel > currentFastMaLevel) == false ) { 
      
         // Should have been greater
         return NO_OP;
      }
   
      slowMACrossTime = Time[barIndex];
      // At this point, index bar 2 is sell, index bar 1 changed to buy, current(index bar 0) bar is sell
      // And a new bar formed        
      return OP_SELL;
   }

   return NO_OP;
}

bool isFastMaAboveSlowMa(ENUM_TIMEFRAMES timeframe, int fastMaPeriod, int slowMaPeriod, bool checkPrevious, int barIndex) {
 
   double currentFastMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
   double currentSlowMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
   
   double previousFastMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
   double previousSlowMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
   
   if ( checkPrevious && ( (previousFastMaLevel > previousSlowMaLevel) == false) ) { 
   
      return false;
   }
   
   if ( (currentFastMaLevel > currentSlowMaLevel) == false ) { 
   
      return false;
   }
   
   return true;
   
}

bool isSlowMaAboveFastMa(ENUM_TIMEFRAMES timeframe, int fastMaPeriod, int slowMaPeriod, bool checkPrevious, int barIndex) {
 
   double currentFastMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
   double currentSlowMaLevel  =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
   
   double previousFastMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, fastMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
   double previousSlowMaLevel =  NormalizeDouble( iMA(SYMBOL, timeframe, slowMaPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex + 1), Digits); 
   
   if ( checkPrevious && ( (previousSlowMaLevel > previousFastMaLevel) == false) ) { 
   
      return false;
   }
   if ( (currentSlowMaLevel > currentFastMaLevel) == false ) { 
   
      return false;
   }

   return true;
}
/** MOVING AVERAGES */

/** MACD */
bool isMACDHistogramAboveZero() {
   double currentMainLevel  =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   return currentMainLevel > 0;
}

bool isMACDHistogramBuy() {
   
   double currentMainLevel  =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   double previousMainLevel =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1), Digits);
   
   double currentSignalLevel  =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR), Digits);
   double previousSignalLevel =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR + 1), Digits);
   
   if ( 
         (currentMainLevel > 0)
         
         && (previousMainLevel > 0) 
         
         && (currentMainLevel > previousMainLevel) 

         /** Previous Signal level within Main histogram */
         // && (previousMainLevel > previousSignalLevel) 

         /** Current Signal level within Main histogram */
         //&&  (currentMainLevel > currentSignalLevel)
      )    
   {
         isMACDHistogramBuy = true;
   }   
   else {
      isMACDHistogramBuy = false;
   }
  
   if (isMACDHistogramBuy) {
      
      /** Should be coming from Negative zone */
      
      double previousThirdMainLevel             =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 2), Digits );
      double previousThirdSignalLevel           =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR + 2), Digits);
      
      double previousFourthMainLevel     =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 3), Digits );      
      double previousFourthSignalLevel   =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR + 3), Digits );      
      
      if ( 
            (previousThirdMainLevel <= 0)
            
            && (previousThirdMainLevel > previousFourthMainLevel) 
   
            /** previousThirdSignalLevel Signal level outside Main histogram - it covers histogrma */
            //&& (previousThirdMainLevel > previousThirdSignalLevel) 
   
            /** previousFourthSignalLevel Signal level outside Main histogram - it covers histogrma */
            //&& (previousFourthMainLevel > previousFourthSignalLevel)
         )
      {   
         if( isMACDHistogramBuy == false) {
            //If condition is met, the sell setup must definately be false
            isMACDHistogramSell   =  false;
            
            //This will allow entering late if filters failed at the time of this setup
            isMACDHistogramBuy  =  true; 
         }        
      } 
      else {
         // Second requirement not met
         isMACDHistogramBuy = false;      
      }
   }
         
   return isMACDHistogramBuy;     
}

bool isMACDHistogramSell() {

   double currentMainLevel    =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits );
   double previousMainLevel   =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1), Digits );
   
   double currentSignalLevel  =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR), Digits);
   double previousSignalLevel =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR + 1), Digits);
   
   if ( (currentMainLevel < 0)
   
         && (previousMainLevel < 0)
   
         && (currentMainLevel < previousMainLevel) 

         /** Previous Signal level within Main histogram */
         //&& (previousMainLevel < previousSignalLevel) 

         /** Current Signal level within Main histogram */
         //&& (currentMainLevel < currentSignalLevel) 
      )   
   {
   
      isMACDHistogramSell = true;
   
   } // end
    
   if (isMACDHistogramSell) {

      
      /** Should be coming from Positive zone */
      
      double previousThirdMainLevel       =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 2), Digits );
      double previousPositiveSignalLevel  =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR + 2), Digits);
      
      double previousFourthMainLevel      =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 3), Digits );      
      double previousFourthSignalLevel    =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, CURRENT_BAR + 3), Digits );  
      
      if ( 
            (previousThirdMainLevel >= 0)
            && (previousThirdMainLevel < previousFourthMainLevel) 
   
            /** previousThirdMainLevel Signal level outside Main histogram - it covers histogram */
            //&& (previousThirdMainLevel < previousPositiveSignalLevel) 
   
            /** previousFourthSignalLevel Signal level outside Main histogram - it covers histogram */
            //&& (previousFourthMainLevel < previousFourthSignalLevel)
         )
      {   
         if( isMACDHistogramSell == false) {
            //If condition is met, the buy setup must definately be false
            isMACDHistogramBuy   =  false;
            
            //This will allow entering late if filters failed at the time of this setup
            isMACDHistogramSell  =  true;
         }
      }
      else {
         
         // Second requirement not met
         isMACDHistogramSell = false;
      }  
      
   } // end isMACDHistogramSell test
      
   return isMACDHistogramSell;
}

bool isMACDHistogramBelowZero() {
   double currentMainLevel  =  NormalizeDouble( iMACD(SYMBOL, CURRENT_TIMEFRAME, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   return currentMainLevel < 0;
}

bool isFilteredNoiseByDamianiVolatmeterV0() {
   
   double currentGreenLine  =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "DamianiVolatmeter", 7, 50, 1.1, true, 2, CURRENT_BAR), Digits); //Green
   double currentSilverLine =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "DamianiVolatmeter", 7, 50, 1.1, true, 0, CURRENT_BAR), Digits); //Silver
  
   double previousGreenLine  =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "DamianiVolatmeter", 7, 50, 1.1, true, 2, CURRENT_BAR + 1), Digits); //Green
   double previousSilverLine =  NormalizeDouble( iCustom (Symbol(), PERIOD_CURRENT, "DamianiVolatmeter", 7, 50, 1.1, true, 0, CURRENT_BAR + 1), Digits); //Silver
  
  
   return ( (currentGreenLine > currentSilverLine) && (previousGreenLine > previousSilverLine) ) == true;
}
/** MACD */

/** CCI */
CciLevelsEnum getCciLevel(int period) {

   double currentCciLevel    =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);

   if( currentCciLevel > CCI_POSITIVE_HUNDRED_LEVEL) {
      
      /** Above 100 */      
      return CCI_ABOVE_POSITIVE_HUNDRED;
   }   
   else if( (currentCciLevel > CCI_ZERO_LEVEL) && (currentCciLevel < CCI_POSITIVE_HUNDRED_LEVEL)) {
      
      /** Between 0 and 100 */
      return CCI_ABOVE_ZERO;
   } 
   else if( currentCciLevel < CCI_NEGATIVE_HUNDRED_LEVEL) {
      
      /** Below -100 */
      return CCI_BELOW_NEGATIVE_HUNDRED;
   }   
   else if( (currentCciLevel < CCI_ZERO_LEVEL) && (currentCciLevel > CCI_NEGATIVE_HUNDRED_LEVEL)) {
      
      /** Between 0 and -100 */
      return CCI_BELOW_ZERO;
   }   
   else {
   
    return CCI_INVALID;
   }
}

bool isCciBuy(int period) {

   //TODO Change to use anytime > 0
   
   /*double currentTwoCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel    =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
   double previousTwoCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 2), Digits);*/

   /** Must be coming from negative zone*/
   /*if( (CCI_ZERO_LEVEL > previousTwoCciLevel) == false ) {
      
      return false;
   }*/
   
   /** Must be inclining */
   /*if( (previousCciLevel > CCI_ZERO_LEVEL) == false ) {
      
      return false;
   }*/
   
   /** Must be inclining */
   
   /*if ( isEmaBelowPriceLevel(period, PRICE_CLOSE, false, false, (CURRENT_BAR + 1) ) == false) {
      
      return false;
   }*/
   
   return isCciGoingAboveZeroLevel(period);
}

bool isCciGoingAboveZeroLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be coming from below 100 */
   if ( (previousCciLevel < CCI_ZERO_LEVEL) == false ) {
      
      return false;
   }
  
   return ( currentCciLevel > CCI_ZERO_LEVEL);
}


bool isCciSell(int period) {

   //TODO Change to use anytime < 0

   /*double currentTwoCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel    =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
   double previousTwoCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 2), Digits);*/
   
   /** Must be coming from positive zone*/
   /*if( (previousTwoCciLevel > CCI_ZERO_LEVEL) == false ) {
      
      return false;
   }*/
   
   /** Must be declining */
   /*if( (CCI_ZERO_LEVEL > previousCciLevel) == false ) {
      
      return false;
   }*/
   
   /** Must be declining */
   //return currentTwoCciLevel < previousCciLevel;
   
   if ( isEmaAbovePriceLevel(period, PRICE_CLOSE, false, false, (CURRENT_BAR + 1) ) == false) {
      
      return false;
   }
   
   return isCciGoingBelowZeroLevel(period);   
   
}

/** This encourages the close of existing buy trades */
bool isCciGoingBelowZeroLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be coming from above 100 */
   if ( (previousCciLevel > CCI_ZERO_LEVEL) == false ) {
      
      return false;
   }
  
   return ( currentCciLevel < CCI_ZERO_LEVEL);
}


bool isCciAboveZeroLevel(int period) {
  
   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be ascending */
   if ( (currentCciLevel > previousCciLevel) == false ) {
      
      return false;
   }
  
   return (previousCciLevel > CCI_ZERO_LEVEL);
}

bool isCciBelowZeroLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be descending */
   if ( (currentCciLevel < previousCciLevel) == false ) {
      
      return false;
   }

   return (previousCciLevel < CCI_ZERO_LEVEL);
}

/** This encourages buy trades */
bool isCciGoingAbovePositiveHundredLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be coming from below 100 */
   if ( (previousCciLevel < CCI_POSITIVE_HUNDRED_LEVEL) == false ) {
      
      return false;
   }
  
   return ( currentCciLevel > CCI_POSITIVE_HUNDRED_LEVEL);
}

/** This encourages the close of existing buy trades */
bool isCciGoingBelowPositiveHundredLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be coming from above 100 */
   if ( (previousCciLevel > CCI_POSITIVE_HUNDRED_LEVEL) == false ) {
      
      return false;
   }
  
   return ( currentCciLevel < CCI_POSITIVE_HUNDRED_LEVEL);
}

/** This encourages sell trades */
bool isCciGoingBelowNegativeHundredLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be coming from above -100 */
   if ( (previousCciLevel > CCI_NEGATIVE_HUNDRED_LEVEL) == false ) {
      
      return false;
   }
  
   return ( currentCciLevel < CCI_NEGATIVE_HUNDRED_LEVEL);
}

/** This encourages the close of existing sell trades */
bool isCciGoingAboveNegativeHundredLevel(int period) {

   double currentCciLevel  =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR), Digits);
   double previousCciLevel =  NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits);
  
   /** Must be coming from below -100 */
   if ( (previousCciLevel < CCI_NEGATIVE_HUNDRED_LEVEL) == false ) {
      
      return false;
   }
  
   return ( currentCciLevel > CCI_NEGATIVE_HUNDRED_LEVEL);
}

bool isCciBuyTrendReversal(int period) {
  
   return (NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits)) < (CCI_POSITIVE_HUNDRED_LEVEL);
}

bool isCciSellTrendReversal(int period) {

   return (NormalizeDouble( iCCI(Symbol(), CURRENT_TIMEFRAME, period, PRICE_TYPICAL, CURRENT_BAR + 1), Digits)) > (CCI_NEGATIVE_HUNDRED_LEVEL);
}
/** CCI */

bool isFilteredNoiseByDamianiVolatmeterV32() {
   
   int       Vis_atr = 13;
   int       Vis_std = 20;
   int       Sed_atr = 40;
   int       Sed_std = 100;
   double    Threshold_level = 1.4;
   bool      lag_supressor = true;

   double currentGreenLine  =  iCustom(Symbol(), PERIOD_CURRENT, "DamianiVolatmeter3.2",Vis_atr, Vis_std, Sed_atr, Sed_std, Threshold_level, 2, CURRENT_BAR);
   double currentSilverLine =  iCustom(Symbol(), PERIOD_CURRENT, "DamianiVolatmeter3.2",Vis_atr, Vis_std, Sed_atr, Sed_std, Threshold_level, 0, CURRENT_BAR);
   
   double previousGreenLine  =  iCustom(Symbol(), PERIOD_CURRENT, "DamianiVolatmeter3.2",Vis_atr, Vis_std, Sed_atr, Sed_std, Threshold_level, 2, CURRENT_BAR + 1);
   double previousSilverLine =  iCustom(Symbol(), PERIOD_CURRENT, "DamianiVolatmeter3.2",Vis_atr, Vis_std, Sed_atr, Sed_std, Threshold_level, 0, CURRENT_BAR + 1);

   return ( (currentGreenLine > currentSilverLine) && (previousGreenLine > previousSilverLine) ) == true;
}

/** ICHIMOKU */
bool isIchimokuBuy() {

   double previousClose = iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
   
   double tenkanSen     =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_TENKANSEN, CURRENT_BAR + 1);
   double kijunSen      =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_KIJUNSEN, CURRENT_BAR + 1);
   double senkouSpanA   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANA, CURRENT_BAR + 1);
   double senkouSpanB   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANB, CURRENT_BAR + 1);
   
   if (
         // previous price close
         previousClose   >  senkouSpanA 
         && previousClose   >  senkouSpanB 
         && previousClose   >  tenkanSen 
         && previousClose   >  kijunSen 
         
         && tenkanSen > kijunSen
         && tenkanSen > senkouSpanA 
         && tenkanSen > senkouSpanB
         
         //Need To?
         //&& kijunSen > senkouSpanA
         //&& kijunSen > senkouSpanB
         
         // Current high is greater that previous close 
         //&& iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR) > previousClose
      )
   {
      return true;
   }
   else {
      return false;
   }
}

bool isIchimokuSell() {

   double previousClose = iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);

   double tenkanSen     =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_TENKANSEN, CURRENT_BAR + 1);
   double kijunSen      =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_KIJUNSEN, CURRENT_BAR + 1);
   double senkouSpanA   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANA, CURRENT_BAR + 1 );
   double senkouSpanB   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANB, CURRENT_BAR + 1);
   
   if (
         // previous price close
         previousClose   <  senkouSpanA 
         && previousClose   <  senkouSpanB 
         && previousClose   <  tenkanSen 
         && previousClose   <  kijunSen 
         
         && tenkanSen < kijunSen
         && tenkanSen < senkouSpanA 
         && tenkanSen < senkouSpanB
         
         //Need To?
         //&& kijunSen < senkouSpanA
         //&& kijunSen < senkouSpanB         

         // Current high is less than previous close 
         //&& iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR) < previousClose          
      )
   {
      return true;
   }
   else {
      return false;
   }
}

bool isPriceNested() {
   
   double senkouSpanA   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANA, CURRENT_BAR + 1 );
   double senkouSpanB   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANB, CURRENT_BAR + 1 );

   
   return ( (Bid < senkouSpanA && Bid > senkouSpanB)
            
            || (Ask < senkouSpanA && Ask > senkouSpanB) 
            
            || (Bid > senkouSpanA && Bid < senkouSpanB) 
            
            || (Ask > senkouSpanA && Ask < senkouSpanB) 
           );
}

bool isPriceNestedOnHigh() {
   
   double senkouSpanA   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANA, CURRENT_BAR + 1 );
   double senkouSpanB   =  iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_SENKOUSPANB, CURRENT_BAR + 1 );

   double previousClose = iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
   
   return ( (previousClose < senkouSpanA && previousClose > senkouSpanB)
            
            || (previousClose < senkouSpanA && previousClose > senkouSpanB) 
            
            || (previousClose > senkouSpanA && previousClose < senkouSpanB) 
            
            || (previousClose > senkouSpanA && previousClose < senkouSpanB) 
           );
}

bool isChikouSpanAbovePriceClose() {

   double chikouSpan   =  NormalizeDouble( iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_CHIKOUSPAN, KIJUN_SEN_PERDIOD), Digits);
   return chikouSpan > iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
}

bool isChikouSpanBelowPriceClose() {

   double chikouSpan   =  NormalizeDouble( iIchimoku(SYMBOL, CURRENT_TIMEFRAME, TENKAN_SEN_PERDIOD, KIJUN_SEN_PERDIOD, SENKOU_SPAN_B_PERDIOD, MODE_CHIKOUSPAN, KIJUN_SEN_PERDIOD), Digits);
   return chikouSpan < iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
}
/** ICHIMOKU */

/** RSI */
void processExtremeConditions() {

   /** Rsi */
   /*if( isRsiOverSold() ) {
   }
   else if( isRsiOverBought() ){
   }
   
   /** Stochastic */
   /*isStochasticOverBought   =  isStochasticOverBought();
   isStochasticOverOverSold =  isStochasticOverOverSold();*/
}
/** RSI */

bool isRsiOverBought(int timeframe, int lBarIndex) {

   double relativeStrengthIndex  =  NormalizeDouble( iRSI(SYMBOL, timeframe, PHD_RSI_DEFAULT_PERIOD, PRICE_MEDIAN, lBarIndex), Digits );
   
   return relativeStrengthIndex > RSI_OVERBOUGHT_LEVEL;
}

bool isRsiOverSold(int timeframe, int lBarIndex) {

   double relativeStrengthIndex  =  NormalizeDouble( iRSI(SYMBOL, timeframe, PHD_RSI_DEFAULT_PERIOD, PRICE_MEDIAN, lBarIndex), Digits );
   
   return relativeStrengthIndex < RSI_OVERSOLD_LEVEL;
}

/** HEIKEN ASHI */
bool isHeikenAshiSmoothBullishTrend(ENUM_TIMEFRAMES timeFrame) {
   
   int high    =  1;
   int open    =  2;
   int close   =  3;
   
   double previousPreviousOpen   =  NormalizeDouble( iCustom(SYMBOL, CURRENT_TIMEFRAME, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, open, CURRENT_BAR + 2), Digits);
   double previousPreviousClose  =  NormalizeDouble( iCustom(SYMBOL, CURRENT_TIMEFRAME, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, CURRENT_BAR + 2), Digits);   
   
   if ( (previousPreviousClose > previousPreviousOpen) == false) {
      return false;
   }

   double previousOpen  =  NormalizeDouble( iCustom(SYMBOL, CURRENT_TIMEFRAME, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, open, CURRENT_BAR + 1), Digits);
   double previousClose =  NormalizeDouble( iCustom(SYMBOL, CURRENT_TIMEFRAME, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, CURRENT_BAR + 1), Digits);
   if ( (previousClose > previousOpen) == false) {
      return false;
   }   

   double currentOpen   =  NormalizeDouble( iCustom(SYMBOL, CURRENT_TIMEFRAME, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, open, CURRENT_BAR), Digits);
   double currentHigh   = NormalizeDouble( iCustom(SYMBOL, CURRENT_TIMEFRAME, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, high, CURRENT_BAR), Digits); 
   if ( (currentHigh > currentOpen) == false) {
      return false;
   }     

   return true;
   
} 

bool isHeikenAshiSmoothBearishTrend(ENUM_TIMEFRAMES timeFrame) {
   
   int low     =  1;
   int open    =  2;
   int close   =  3;

   double previousPreviousOpen   =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, open, CURRENT_BAR + 2), Digits);
   double previousPreviousClose  =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, CURRENT_BAR + 2), Digits);   
   
   if ( (previousPreviousOpen > previousPreviousClose ) == false) {
      return false;
   }

   double previousOpen  =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, open, CURRENT_BAR + 1), Digits);
   double previousClose =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, CURRENT_BAR + 1), Digits);
   if ( ( previousOpen > previousClose) == false) {
      return false;
   }   

   double currentOpen   =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, open, CURRENT_BAR), Digits);
   double currentLow   = NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, low, CURRENT_BAR), Digits); 
   if ( (currentOpen> currentLow ) == false) {
      return false;
   }     

   return true;
   
}

bool isPriceActionAboveHeikenAshiSmooth(ENUM_TIMEFRAMES timeFrame, int barIndex) {

   int close   =  3;
   double haClose  =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, barIndex), Digits);
   
   double barOpen = iOpen(SYMBOL, timeFrame, barIndex);
   double barClose  = iClose(SYMBOL, timeFrame, barIndex);   
   /*if ( ( barClose > barOpen ) == false ) {
      return false;
   }*/

   return barClose > haClose;

} 

bool isPriceActionBelowHeikenAshiSmooth(ENUM_TIMEFRAMES timeFrame, int barIndex) {
   
   int close      =  3;
   double haClose =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, barIndex), Digits);
   
   
   double barOpen    =  iOpen(SYMBOL, timeFrame, barIndex);
   double barClose   =  iClose(SYMBOL, timeFrame, barIndex);   
   /*if ( (barOpen > barClose) == false ) {
      return false;
   }*/
   
   return barClose < haClose;
   
}

bool isHeikenAshiSmoothAboveMa(int maPeriod, ENUM_TIMEFRAMES timeFrame, int barIndex) {

   int close         =  3;
   double haClose    =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, barIndex), Digits);
   double maLevel    =  NormalizeDouble( iMA(SYMBOL, timeFrame, maPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
  
   return haClose > maLevel;

} 

bool isHeikenAshiSmoothBelowMa(int maPeriod, ENUM_TIMEFRAMES timeFrame, int barIndex) {
   
   int close   =  3;
   double haClose  =  NormalizeDouble( iCustom(SYMBOL, timeFrame, "Heiken_Ashi_Smoothed", 2, 6, 3, 2, close, barIndex), Digits);
   double maLevel  =  NormalizeDouble( iMA(SYMBOL, timeFrame, maPeriod, MA_SHIFT, MA_METHOD, PRICE_CLOSE, barIndex), Digits); 
   
   return maLevel > haClose;
   
}
/** HEIKEN ASHI */


/** LONDON BREAKOUT */
//TODO Use 1H for setup - try using 15 to trigger
int getLondonBreakOutBuy(int lLondonSessionOpenHour) {
      
   if ( (Hour() == lLondonSessionOpenHour) && (londonBreakOutHighestPriceProcessedTime != Time[CURRENT_BAR]) ) {
   
      if ( DayOfWeek() == 0 || DayOfWeek() == 6) { //Exclude Sat and Sunday
      
         return -1;
      }   
      
      londonBreakOutHighestPriceProcessedTime   =  Time[CURRENT_BAR];
      
      int highestIndex           =  iHighest(SYMBOL, CURRENT_TIMEFRAME, MODE_HIGH, breakOutBarsEndIndex, breakOutBarsStartIndex);
      londonBreakOutHighestPrice =  iHigh(SYMBOL, CURRENT_TIMEFRAME, highestIndex);
      
      // Capture the lowest and apply SL
      int lowestIndex            =  iLowest(SYMBOL, CURRENT_TIMEFRAME, MODE_HIGH, breakOutBarsEndIndex, breakOutBarsStartIndex);
      londonBreakOutLowestPrice  =  iLow(SYMBOL, CURRENT_TIMEFRAME, lowestIndex);
      initialLondonBreakOutBuyStopLevel    =  NormalizeDouble( londonBreakOutLowestPrice - (initialLondonBreakOutStopPoints * getDecimalPip()), Digits ); 
      
      // Don't use the open hour to trade - use any highest close/high after this bar or the previous 4
      return -1;
   }

   if ( 
      
      (Hour() < londonBoExitTradeHour) &&
      
      ( TimeYear(londonBreakOutHighestPriceProcessedTime) == TimeYear(TimeCurrent() )) &&
   
      ( TimeDayOfYear(londonBreakOutHighestPriceProcessedTime) == TimeDayOfYear(TimeCurrent() )) &&
   
      (londonBreakOutHighestPrice != 0.0 && (londonBreakOutBuyTime != Time[CURRENT_BAR]) && (londonBreakOutBuyUsedDayOfWeek != DayOfWeek()) )
      
      ) {
      
      if ( appliedPrice == PRICE_HIGH) {
      
         double currentHigh   =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
         if ( currentHigh > londonBreakOutHighestPrice) {
            
            londonBreakOutBuyTime = Time[CURRENT_BAR];
            londonBreakOutBuyUsedDayOfWeek = DayOfWeek();            
            
            initialLondonBreakOutBuyTakeProfitLevel   =  NormalizeDouble( currentHigh + (initialLondonBreakOutTakeProfitPoints * getDecimalPip()), Digits );       
            
            return OP_BUY;
         }
      }
      else if ( appliedPrice == PRICE_CLOSE) { 
      
         double previousClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
         if ( previousClose > londonBreakOutHighestPrice) {
            
            londonBreakOutBuyTime = Time[CURRENT_BAR];
            londonBreakOutBuyUsedDayOfWeek = DayOfWeek();
            
            initialLondonBreakOutBuyTakeProfitLevel   =  NormalizeDouble( previousClose + (initialLondonBreakOutTakeProfitPoints * getDecimalPip()), Digits );                   
            return OP_BUY;
         }
      
      }
      else {
         
         return -1;   
      }
   }

   return -1;   
}

int getLondonBreakOutSell(int lLondonSessionOpenHour) {


   if ( (Hour() == lLondonSessionOpenHour) && (londonBreakLowestPriceProcessedTime != Time[CURRENT_BAR]) ) {
   
            
      if ( DayOfWeek() == 0 || DayOfWeek() == 6) { //Exclude Sat and Sunday
      
         return -1;
      }
      
      londonBreakLowestPriceProcessedTime = Time[CURRENT_BAR];
      
      int lowestIndex            =  iLowest(SYMBOL, CURRENT_TIMEFRAME, MODE_HIGH, breakOutBarsEndIndex, breakOutBarsStartIndex);
      londonBreakOutLowestPrice  =  iLow(SYMBOL, CURRENT_TIMEFRAME, lowestIndex);
      
      // Capture the highest and apply SL
      int highestIndex           =  iHighest(SYMBOL, CURRENT_TIMEFRAME, MODE_HIGH, breakOutBarsEndIndex, breakOutBarsStartIndex);
      londonBreakOutHighestPrice =  iHigh(SYMBOL, CURRENT_TIMEFRAME, highestIndex);
      initialLondonBreakOutSellStopLevel   =  NormalizeDouble( londonBreakOutHighestPrice + (initialLondonBreakOutStopPoints * getDecimalPip()), Digits );       
      
      // Don't use the open hour to trade - use any highest close/high after this bar or the previous 4
      return -1;
   }
   
   if ( 
   
      (Hour() < londonBoExitTradeHour) &&
   
      ( TimeYear(londonBreakLowestPriceProcessedTime) == TimeYear(TimeCurrent() )) &&
   
      ( TimeDayOfYear(londonBreakLowestPriceProcessedTime) == TimeDayOfYear(TimeCurrent() )) &&
         
      (londonBreakOutLowestPrice != 0.0 && (londonBreakOutSellTime != Time[CURRENT_BAR]) && (londonBreakOutSellUsedDayOfWeek != DayOfWeek()))
      
      
      ) {
      
      if ( appliedPrice == PRICE_HIGH) {
      
         double currentLow   =  iLow(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
         if ( currentLow < londonBreakOutLowestPrice) {
            
            londonBreakOutSellTime = Time[CURRENT_BAR];
            londonBreakOutSellUsedDayOfWeek = DayOfWeek();
            
            initialLondonBreakOutSellTakeProfitLevel   =  NormalizeDouble( currentLow - (initialLondonBreakOutTakeProfitPoints * getDecimalPip()), Digits );       
            
            return OP_SELL;
         }
      }
      else if ( appliedPrice == PRICE_CLOSE) { 
      
         double previousClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
         if ( previousClose < londonBreakOutLowestPrice) {
            
            londonBreakOutSellTime = Time[CURRENT_BAR];
            londonBreakOutSellUsedDayOfWeek = DayOfWeek();
                        
            initialLondonBreakOutSellTakeProfitLevel   =  NormalizeDouble( previousClose + (initialLondonBreakOutTakeProfitPoints * getDecimalPip()), Digits );                                           
            return OP_SELL;
         }
      
      }
      else {
         
         return -1;   
      } 
   }  

   return -1;   
}
/** LONDON BREAKOUT */

/** BOLLINGER BANDS */
bool isPriceCloseAboveMiddleBand(int period) {
   
   double bandLevel     =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1), Digits);
   double previousClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
   
   return (previousClose > bandLevel);
}

bool isPriceCloseBelowMiddleBand(int period) {
   
   double bandLevel     =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1), Digits);
   double previousClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR + 1);
      
   return (previousClose < bandLevel);   
}

bool isIbandMiddleBandAscending(int period) {
   
   double bandLevelCurrent    =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   double bandLevelPrevious   =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1), Digits);
   
   return bandLevelCurrent > bandLevelPrevious;
}

bool isIbandMiddleBandDescending(int period) {
   
   double bandLevelCurrent    =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   double bandLevelPrevious   =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1), Digits);

   return bandLevelCurrent < bandLevelPrevious;
}

bool isPriceHighAboveMiddleBand(int period) {
   
   double bandLevel = NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   double currentHigh   =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR); 
   
   return (currentHigh > bandLevel);
   
}

bool isPriceLowBelowMiddleBand(int period) {
   
   double bandLevel  =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR), Digits);
   double currentLow =  iHigh(SYMBOL, CURRENT_TIMEFRAME, CURRENT_BAR);
      
   return (currentLow < bandLevel);  
   
}

bool isPriceCloseWithinBbands(int barIndex, int period) {
   
   double previousClose    =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex); 
   double lowerBbandLevel  =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_LOWER, barIndex), Digits);
   double upperBbandLevel  =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_UPPER, barIndex), Digits);
      
   return (previousClose > lowerBbandLevel) && (previousClose < upperBbandLevel);
   
}

bool isPriceCloseAboveUpperBband(int period, int barIndex) {

   double pricelose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex);
   double upperBband =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_UPPER, barIndex), Digits);
      
   return (pricelose > upperBband);  
   
}

bool isPriceCloseBelowLowerBband(int period, int barIndex) {
   
   double pricelose  =  iClose(SYMBOL, CURRENT_TIMEFRAME, barIndex);
   double lowerBband =  NormalizeDouble( iBands(SYMBOL, CURRENT_TIMEFRAME, period, STANDARD_DEV, 0, PRICE_CLOSE, MODE_LOWER, barIndex), Digits);
      
   return (lowerBband > pricelose);
   
}
/** BOLLINGER BANDS */

/** ADX */
bool isAdxTrendGainingMomentum() {
   
   /* Current ADX must be greater than previous */
   return ( 
            /*( (iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_HIGH, MODE_MAIN, CURRENT_BAR)) > 
               (iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1)) ) &&*/
               
            ( (iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 1) ) > 
               iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_MAIN, CURRENT_BAR + 2) ) ) ;
}

bool isAdxBuySignal() {
   
   /* MODE_PLUSDI > MODE_MINUSDI */
   return iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_PLUSDI, CURRENT_BAR + 1) > 
   iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_MINUSDI, CURRENT_BAR + 1);
}

bool isAdxSellSignal() {
   
   /* MODE_MINUSDI > MODE_PLUSDI */
   return iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_MINUSDI, CURRENT_BAR + 1) > 
   iADX(SYMBOL, CURRENT_TIMEFRAME, PHD_ADX_PERIOD, PRICE_CLOSE, MODE_PLUSDI, CURRENT_BAR + 1);
}
/** ADX */

/** PREVIOUS DAY */
bool wasPreviousDayBullish() {

   double previousDayOpen = iOpen(SYMBOL, PERIOD_D1, CURRENT_BAR + 1);
   double previousDayClose = iClose(SYMBOL, PERIOD_D1, CURRENT_BAR + 1);
   
   return (previousDayClose > previousDayOpen);
}

bool wasPreviousDayBearish() {

   double previousDayOpen = iOpen(SYMBOL, PERIOD_D1, CURRENT_BAR + 1);
   double previousDayClose = iClose(SYMBOL, PERIOD_D1, CURRENT_BAR + 1);
   
   return (previousDayOpen > previousDayClose );   
} 
/** PREVIOUS DAY */


int getSlipage(int lSlippagePoints) {
   return lSlippagePoints * Point * 10;
}

//Test MA
void testMa() {
   
   double emaLevel  =  NormalizeDouble( iMA(NULL, 0, 55, 0, MODE_EMA, PRICE_CLOSE, 1), Digits); 
   double bandLevel = iBands(NULL, 0, 55, 2, 0, PRICE_CLOSE, MODE_MAIN, 1);
   
   double previousClose =  iClose(SYMBOL, CURRENT_TIMEFRAME, 1);
   
   if ( (previousClose > emaLevel) ) {
      
      Print("MA BUY");
   }
   
   else if ( (emaLevel > previousClose) ) {
      
      Print("MA SELL");
   }
   
   
   
   if ( (previousClose > bandLevel) ) {
      
      Print("BAND BUY");
   }
   
   else if ( (bandLevel > previousClose) ) {
   
      Print("BAND SELL");
   }   
   
   
}