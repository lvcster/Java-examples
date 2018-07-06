//+------------------------------------------------------------------+
//|                                            Tabela_kontrolna.mq4 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_separate_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
double    swaplong,swapshort,MARGINREQUIRED, highday, lowday;
int spread, DigitsAfterDecimalPoints;
// kolor sygnalu
extern color signalBuyColor=LimeGreen, // dla kupna
             signalSellColor=Red, // dla sprzedazy FireBrick
             noSignalColor=Silver, // neutralny
             textColor=Ivory, // dla tekstu wskaznika
             GroupTxtColor=DarkGray,// dla tekstu grup wskaznikow
             MarketTxtColor=LightBlue; // dla tekstu info... z rynku
             
extern bool   show.Bclk=true;
int   TimeFrame   =0 ;

int sizeTxt = 7, // rozmiar tekst
    sizeGroupTxt = 9; // rozmiar tekstu grupowania

int f[50]; //Array of 50 elements (for prospect, up to 50 indicators)

//1. Acceleration/Deceleration — AC
extern int piac=0; //Indicator period

//2. Accumulation/Distribution - A/D
extern int piad=0; //Indicator period
extern int piad2=0; //Price period

//3. Alligator & Fractals
extern int piall=0; //Indicator period
extern int piall2=0; //Price period
extern int pifr=0; //Period of fractals

extern int jaw_period=13;
extern int jaw_shift=8;
extern int teeth_period=8;
extern int teeth_shift=5;
extern int lips_period=5;
extern int lips_shift=3;

//4. Gator Oscillator
// Part of variables from "3. Alligator & Fractals" is used
extern int piga=0; //Indicator period

//5. Average Directional Movement Index - ADX
extern int piadx=0; //Indicator period
extern int piadu=14; //Period of averaging for index calculation
extern double minadx=20; //Minimal threshold value of ADX

//6. Average True Range - ATR
extern int piatr=0; //Indicator period
extern int piatru=14; //Period of averaging for indicator calculation
extern double minatr=0.0002; //Minimal threshold value of ATR

//7. Awesome Oscillator
extern int piao=0; //Indicator period

//8. Bears Power
extern int pibear=0; //Indicator period
extern int pibearu=13; //Period of averaging for indicator calculation

//9. Bollinger Bands
extern int piband=0; //Indicator period
extern int pibandu=20; //Period of averaging for indicator calculation
extern int ibandotkl=2; //Deviation from the main line
extern int piband2=0; //Price period

//10. Bulls Power
extern int pibull=0; //Indicator period
extern int pibullu=13; //Period of averaging for indicator calculation

//11. Commodity Channel Index
extern int picci=0; //Indicator period
extern int picciu=14; //Period of averaging for indicator calculation

//12. DeMarker
extern int pidem=0; //Indicator period
extern int pidemu=14; //Period of averaging for indicator calculation

//13. Envelopes
extern int pienv=0; //Indicator period
extern int pienvu=14; //Period of averaging for indicator calculation
extern int ienvshift=0; //Indicator shift relative to a chart 
extern double ienvotkl=0.07; //Deviation from the main line in percent
extern int pienv2=0; //Price period

//14. Force Index
extern int piforce=0; //Indicator period
extern int piforceu=2; //Period of averaging for indicator calculation

//15,16,17. Ichimoku Kinko Hyo
extern int pich=0; //Indicator period
extern int ptenkan=9; //Tenkan-Sen Period (9)
extern int pkijun=26; //Kijun-Sen Period (26)
extern int psenkou=52; //Senkou Span B Period (52)
extern int pich2=0; //Price period

//18. Money Flow Index - MFI
extern int pimfi=0; //Indicator period
extern int barsimfi=14; //Period (amount of bars) for indicator calculation

//19. Moving Average
extern int pima=0; //Indicator period
extern int pimau=14; //Period of averaging for indicator calculation

//20,21,22,23. MACD and Moving Average of Oscillator (histogram MACD)
extern int pimacd=0; //Indicator period
extern int fastpimacd=12; //Averaging period for calculation of a quick MA
extern int slowpimacd=26; //Averaging period for calculation of a slow MA
extern int signalpimacd=9; //Averaging period for calculation of a signal line

//24. Parabolic SAR
extern int pisar=0; //Indicator period
extern double isarstep=0.02; //Stop level increment
extern double isarstop=0.2; //Maximal stop level
extern int pisar2=0; //Price period

//25. RSI
extern int pirsi=0; //Indicator period
extern int pirsiu=14; //Period of averaging for indicator calculation
 
//26. RVI
extern int pirvi=0; //Indicator period
extern int pirviu=10; //Period of averaging for indicator calculation

//27. Standard Deviation
extern int pistd=0; //Indicator period
extern int pistdu=20; //Period of averaging for indicator calculation

//28, 29. Stochastic Oscillator
extern int pisto=0; //Indicator period
extern int pistok=5; //Period(amount of bars) for the calculation of %K line
extern int pistod=3; //Averaging period for the calculation of %D line
extern int istslow=3; //Value of slowdown

//30. Williams Percent Range
extern int piwpr=0; //Indicator period
extern int piwprbar=14; //Period (amount of bars) for indicator calculation

int init()
  {
  IndicatorShortName("Tabela kontrolna ("+Symbol()+")");
  
  highday=MarketInfo(Symbol(),2);
  lowday=MarketInfo(Symbol(),1);
  spread=MarketInfo(Symbol(),13);
  swaplong=NormalizeDouble(MarketInfo(Symbol(),18),2);
  swapshort=NormalizeDouble(MarketInfo(Symbol(),19),2);
  MARGINREQUIRED=NormalizeDouble(MarketInfo(Symbol(),32),2)/100;
  DigitsAfterDecimalPoints=MarketInfo(Symbol(),12);
   
  switch(TimeFrame)
     {
      case 1  : string TimeFrameStr="M1";  break;
      case 5  :     TimeFrameStr=   "M5";  break;
      case 15 :     TimeFrameStr=   "M15";   break;
      case 30 :     TimeFrameStr=   "M30";   break;
      case 60 :     TimeFrameStr=   "H1";  break;
      case 240  :   TimeFrameStr=   "H4";  break;
      case 1440 :   TimeFrameStr=   "D1";  break;
      case 10080 :  TimeFrameStr=   "W1";  break;
      case 43200 :  TimeFrameStr=   "MN1";   break;
      default  :    TimeFrameStr=   "CurrTF";
     }
  
  return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   ObjectsDeleteAll();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

//----------variables of flags permanently significant----------
//Due to their character these flags do not turn into zero
int f5=0; //5. Average Directional Movement Index - ADX
int f19=0; //19. Moving Average
int f26=0; //26. RVI
int f29=0; //29. Stochastic Oscillator (2)

int start()
  {
  
 HideTestIndicators(true); //Hiding charts and indicator (oscillator) windows
 
 double i,i1,i2,i3,i4,i5,i6,i7;
   int m,s,k,
   m0, m1,m2,m3,m4,m5,m6,m7,
   s0, s1,s2,s3,s4,s5,s6,s7,
   h,h1,h2,h3,h4,h5,h6,h7;
   if (TimeFrame ==0)TimeFrame=Period();
   m=iTime(NULL,TimeFrame,0)+TimeFrame*60 - TimeCurrent();
   //  m=Time[0]+Period()*60-CurTime();
   m1=iTime(NULL,1440,0)+1440*60-CurTime();
   m2=iTime(NULL,240,0)+240*60-CurTime();
   m3=iTime(NULL,60,0)+60*60-CurTime();
   m4=iTime(NULL,30,0)+30*60-CurTime();
   m5=iTime(NULL,15,0)+15*60-CurTime();
   m6=iTime(NULL,5,0)+5*60-CurTime();
   m7=iTime(NULL,1,0)+1*60-CurTime();
//----
   i=m/60.0;
   i1=m1/60.0;
   i2=m2/60.0;
   i3=m3/60.0;
   i4=m4/60.0;
   i5=m5/60.0;
   i6=m6/60.0;
   i7=m7/60.0;
//----
   s=m%60;
   s0=m%60;
   s1=m1%60;
   s2=m2%60;
   s3=m3%60;
   s4=m4%60;
   s5=m5%60;
   s6=m6%60;
   s7=m7%60;
//----
   m=(m-m%60)/60;
   m0=(m-m%60)/60;
   m1=(m1-m1%60)/60;
   m2=(m2-m2%60)/60;
   m3=(m3-m3%60)/60;
   m4=(m4-m4%60)/60;
   m5=(m5-m5%60)/60;
   m6=(m6-m6%60)/60;
   m7=(m7-m7%60)/60;
//----
   h=m/60;
   h1=m1/60;
   h2=m2/60;
   h3=m3/60;
   h4=m4/60;
   h5=m5/60;
   h6=m6/60;
   h7=m7/60;
//----
   string Bclk=   "                   <"+m+":"+s;
   string M1=  "[M1] "+m7+"m :"+s7;
   string M5=  "[M5] "+m6+"m :"+s6;
   string M15= "[M15] "+m5+"m :"+s5;
   string M30= "[M30] "+m4+"m :"+s4;
   string M60= "[M60] "+m3+"m :"+s3;
   string M240= "[H4] "+m2+"m :"+s2;
   string M1440= "[D1] "+m1+"m :"+s1;
//----

   if(show.Bclk )
     {
     Comment( m + " minut/y " + s + " sekund/y do koñca œwieczki");}
   ObjectDelete("time");
   if(ObjectFind("time")!=0)
     {
        if(show.Bclk )
        {
        ObjectCreate("time", OBJ_TEXT, 0, Time[0], Close[0]+ 0.0000);}
        if(show.Bclk )
        {
        ObjectSetText("time",StringSubstr((Bclk),0), 8, "Tahoma" ,Gold);}
      //ObjectDelete("time");
     }
   else
     {
      ObjectMove("time", 0, Time[0], Close[0]+0.0005);
      //ObjectDelete("time");
     }
     
//----------Variables of flag significant pointwise----------
//These flags can turn into zero
int f1=0; //1. Acceleration/Deceleration — AC
int f2=0; //2. Accumulation/Distribution - A/D
int f3=0; //3. Alligator & Fractals
int f4=0; //4. Gator Oscillator
int f6=0; //6. Average True Range - ATR
int f7=0; //7. Awesome Oscillator
int f8=0; //8. Bears Power
int f9=0; //9. Bollinger Bands
int f10=0; //10. Bulls Power
int f11=0; //11. Commodity Channel Index
int f12=0; //12. DeMarker
int f13=0; //13. Envelopes
int f14=0; //14. Force Index
int f15=0; //15. Ichimoku Kinko Hyo (1)
int f16=0; //16. Ichimoku Kinko Hyo (2)
int f17=0; //17. Ichimoku Kinko Hyo (3)
int f18=0; //18. Money Flow Index - MFI
int f20=0; //20. MACD (1)
int f21=0; //21. MACD (2)
int f22=0; //22. Moving Average of Oscillator (MACD histogram) (1)
int f23=0; //23. Moving Average of Oscillator (MACD histogram) (2)
int f24=0; //24. Parabolic SAR
int f25=0; //25. RSI
int f27=0; //27. Standard Deviation
int f28=0; //28. Stochastic Oscillator (1)
int f30=0; //30. Williams Percent Range


  
//----
int err=0; //Checking errors
int order=0;
int flag=0; //The main flag of the strategic block


   {    
       
//----------Strategic block----------//

//1. Acceleration/Deceleration — AC
//Buy: if the indicator is above zero and 2 consecutive columns are green or if the indicator is below zero and 3 consecutive columns are green
//Sell: if the indicator is below zero and 2 consecutive columns are red or if the indicator is above zero and 3 consecutive columns are red
if ((iAC(NULL,piac,0)>=0&&iAC(NULL,piac,0)>iAC(NULL,piac,1)&&iAC(NULL,piac,1)>iAC(NULL,piac,2))||(iAC(NULL,piac,0)<=0&&iAC(NULL,piac,0)>iAC(NULL,piac,1)&&iAC(NULL,piac,1)>iAC(NULL,piac,2)&&iAC(NULL,piac,2)>iAC(NULL,piac,3)))
{f1=1;}
if ((iAC(NULL,piac,0)<=0&&iAC(NULL,piac,0)<iAC(NULL,piac,1)&&iAC(NULL,piac,1)<iAC(NULL,piac,2))||(iAC(NULL,piac,0)>=0&&iAC(NULL,piac,0)<iAC(NULL,piac,1)&&iAC(NULL,piac,1)<iAC(NULL,piac,2)&&iAC(NULL,piac,2)<iAC(NULL,piac,3)))
{f1=-1;}


//2. Accumulation/Distribution - A/D
//Main principle - convergence/divergence
//Buy: indicator growth at downtrend
//Sell: indicator fall at uptrend
if (iAD(NULL,piad,0)>=iAD(NULL,piad,1)&&iClose(NULL,piad2,0)<=iClose(NULL,piad2,1))
{f2=1;}
if (iAD(NULL,piad,0)<=iAD(NULL,piad,1)&&iClose(NULL,piad2,0)>=iClose(NULL,piad2,1))
{f2=-1;}

//3. Alligator & Fractals
//Buy: all 3 Alligator lines grow/ don't fall/ (3 periods in succession) and fractal (upper line) is above teeth
//Sell: all 3 Alligator lines fall/don't grow/ (3 periods in succession) and fractal (lower line) is below teeth
//Fracal shift=2 because of the indicator nature
if (iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,2)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,0)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,2)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,0)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,2)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,0)&&iFractals(NULL,pifr,MODE_UPPER,2)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,0))
{f3=1;}
if (iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,2)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,0)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,2)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,0)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,2)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1)&&iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1)>=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,0)&&iFractals(NULL,pifr,MODE_LOWER,2)<=iAlligator(NULL,piall,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,0))
{f3=-1;}

//4. Gator Oscillator
//Doesn't give independent signals. Is used for Alligator correction.
//Principle: trend must be strengthened. Together with this Gator Oscillator goes up.
//Lower part of diagram is taken for calculations. Growth is checked on 4 periods.
//The flag is 1 of trend is strengthened, 0 - no strengthening, -1 - never.
//Uses part of Alligator's variables
if (iGator(NULL,piga,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,3)>iGator(NULL,piga,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,2)&&iGator(NULL,piga,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,2)>iGator(NULL,piga,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,1)&&iGator(NULL,piga,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,1)>iGator(NULL,piga,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,0))
{f4=1;}

//Joining flags 3 and 4
if (f3==1&&f4==1)
{f4=1;}
if (f3==-1&&f4==1)
{f4=-1;}
f3=0; //Flag 3 is not used any more 


//5. Average Directional Movement Index - ADX
//Buy: +DI line is above -DI line, ADX is more than a certain value and grows (i.e. trend strengthens)
//Sell: -DI line is above +DI line, ADX is more than a certain value and grows (i.e. trend strengthens)
if (iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MINUSDI,0)<iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_PLUSDI,0)&&iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MAIN,0)>=minadx&&iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MAIN,0)>iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MAIN,1))
{f5=1;}
if (iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MINUSDI,0)>iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_PLUSDI,0)&&iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MAIN,0)>=minadx&&iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MAIN,0)>iADX(NULL,piadx,piadu,PRICE_CLOSE,MODE_MAIN,1))
{f5=-1;}

//6. Average True Range - ATR
//Doesn't give independent signals. Is used to define volatility (trend strength).
//principle: trend must be strengthened. Together with that ATR grows.
//Because of the chart form it is inconvenient to analyze rise/fall. Only exceeding of threshold value is checked.
//Flag is 1 when ATR is above threshold value (i.e. there is a trend), 0 - when ATR is below threshold value, -1 - never.
if (iATR(NULL,piatr,piatru,0)>=minatr)
{f6=1;}

//7. Awesome Oscillator
//Buy: 1. Signal "saucer" (3 positive columns, medium column is smaller than 2 others); 2. Changing from negative values to positive.
//Sell: 1. Signal "saucer" (3 negative columns, medium column is larger than 2 others); 2. Changing from positive values to negative.
if ((iAO(NULL,piao,2)>0&&iAO(NULL,piao,1)>0&&iAO(NULL,piao,0)>0&&iAO(NULL,piao,1)<iAO(NULL,piao,2)&&iAO(NULL,piao,1)<iAO(NULL,piao,0))||(iAO(NULL,piao,1)<0&&iAO(NULL,piao,0)>0))
{f7=1;}
if ((iAO(NULL,piao,2)<0&&iAO(NULL,piao,1)<0&&iAO(NULL,piao,0)<0&&iAO(NULL,piao,1)>iAO(NULL,piao,2)&&iAO(NULL,piao,1)>iAO(NULL,piao,0))||(iAO(NULL,piao,1)>0&&iAO(NULL,piao,0)<0))
{f7=-1;}

//8. Bears Power
//Is used only together with a trend indicator. Gives only Buy signals.
//Flag is 1, if the indicator is negative and grows, 0 - in all other cases, -1 - never.
if (iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,2)<0&&iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,1)<0&&iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,0)<0&&iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,2)<iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,1)&&iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,1)<iBearsPower(NULL,pibear,pibearu,PRICE_CLOSE,0))
{f8=1;}

//9. Bollinger Bands
//Buy: price crossed lower line upwards (returned to it from below)
//Sell: price crossed upper line downwards (returned to it from above)
if (iBands(NULL,piband,pibandu,ibandotkl,0,PRICE_CLOSE,MODE_LOWER,1)>iClose(NULL,piband2,1)&&iBands(NULL,piband,pibandu,ibandotkl,0,PRICE_CLOSE,MODE_LOWER,0)<=iClose(NULL,piband2,0))
{f9=1;}
if (iBands(NULL,piband,pibandu,ibandotkl,0,PRICE_CLOSE,MODE_UPPER,1)<iClose(NULL,piband2,1)&&iBands(NULL,piband,pibandu,ibandotkl,0,PRICE_CLOSE,MODE_UPPER,0)>=iClose(NULL,piband2,0))
{f9=-1;}

//10. Bulls Power
//Is used only together with a trend indicator. Gives only Sell signals.
//Flag is -1, if the indicator is positive and falls, 0 - in all other cases, 1 - never.
if (iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,2)>0&&iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,1)>0&&iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,0)>0&&iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,2)>iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,1)&&iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,1)>iBullsPower(NULL,pibull,pibullu,PRICE_CLOSE,0))
{f10=-1;}
//f10=0; //Now we don't use

//11. Commodity Channel Index
//Buy: 1. indicator crosses +100 from below upwards. 2. Crossing -100 from below upwards. 3.
//Sell: 1. indicator crosses -100 from above downwards. 2. Crossing +100 downwards. 3.
if ((iCCI(NULL,picci,picciu,PRICE_TYPICAL,1)<100&&iCCI(NULL,picci,picciu,PRICE_TYPICAL,0)>=100)||(iCCI(NULL,picci,picciu,PRICE_TYPICAL,1)<-100&&iCCI(NULL,picci,picciu,PRICE_TYPICAL,0)>=-100))
{f11=1;}
if ((iCCI(NULL,picci,picciu,PRICE_TYPICAL,1)>-100&&iCCI(NULL,picci,picciu,PRICE_TYPICAL,0)<=-100)||(iCCI(NULL,picci,picciu,PRICE_TYPICAL,1)>100&&iCCI(NULL,picci,picciu,PRICE_TYPICAL,0)<=100))
{f11=-1;}

//12. DeMarker
//Buy: 1. Crossing 0.3 level bottom-up.
//Sell: 1. Crossing 0.7 level downwards.
if(iDeMarker(NULL,pidem,pidemu,1)<0.3&&iDeMarker(NULL,pidem,pidemu,0)>=0.3)
{f12=1;}
if(iDeMarker(NULL,pidem,pidemu,1)>0.7&&iDeMarker(NULL,pidem,pidemu,0)<=0.7)
{f12=-1;}

//13. Envelopes
//Buy: price crossed lower line upwards (returned to it from below)
//Sell: price crossed upper line downwards (returned to it from above)
if(iEnvelopes(NULL,pienv,pienvu,MODE_SMA,ienvshift,PRICE_CLOSE,ienvotkl,MODE_LOWER,1)>iClose(NULL,pienv2,1)&&iEnvelopes(NULL,pienv,pienvu,MODE_SMA,ienvshift,PRICE_CLOSE,ienvotkl,MODE_LOWER,0)<=iClose(NULL,pienv2,0))
{f13=1;}
if(iEnvelopes(NULL,pienv,pienvu,MODE_SMA,ienvshift,PRICE_CLOSE,ienvotkl,MODE_UPPER,1)<iClose(NULL,pienv2,1)&&iEnvelopes(NULL,pienv,pienvu,MODE_SMA,ienvshift,PRICE_CLOSE,ienvotkl,MODE_UPPER,0)>=iClose(NULL,pienv2,0))
{f13=-1;}

//14. Force Index
//To use the indicator it should be correlated with another trend indicator
//Flag 14 is 1, when FI recommends to buy (i.e. FI<0)
//Flag 14 is -1, when FI recommends to sell (i.e. FI>0)
if (iForce(NULL,piforce,piforceu,MODE_SMA,PRICE_CLOSE,0)<0)
{f14=1;}
if (iForce(NULL,piforce,piforceu,MODE_SMA,PRICE_CLOSE,0)>0)
{f14=-1;}

//15. Ichimoku Kinko Hyo (1)
//Buy: Price crosses Senkou Span-B upwards; price is outside Senkou Span cloud
//Sell: Price crosses Senkou Span-B downwards; price is outside Senkou Span cloud
if (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)>iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)<=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)<iClose(NULL,pich2,0))
{f15=1;}
if (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)<iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)>=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)>iClose(NULL,pich2,0))
{f15=-1;}

//16. Ichimoku Kinko Hyo (2)
//Buy: Tenkan-sen crosses Kijun-sen upwards
//Sell: Tenkan-sen crosses Kijun-sen downwards
//VERSION EXISTS, IN THIS CASE PRICE MUSTN'T BE IN THE CLOUD!
if (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,1)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,0)>=iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,0))
{f16=1;}
if (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,1)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,0)<=iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,0))
{f16=-1;}

//17. Ichimoku Kinko Hyo (3)
//Buy: Chinkou Span crosses chart upwards; price is ib the cloud
//Sell: Chinkou Span crosses chart downwards; price is ib the cloud
if ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)<iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)>=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
{f17=1;}
if ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)>iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)<=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
{f17=-1;}

//18. Money Flow Index - MFI
//Buy: Crossing 20 upwards
//Sell: Crossing 20 downwards
if(iMFI(NULL,pimfi,barsimfi,1)<20&&iMFI(NULL,pimfi,barsimfi,0)>=20)
{f18=1;}
if(iMFI(NULL,pimfi,barsimfi,1)>80&&iMFI(NULL,pimfi,barsimfi,0)<=80)
{f18=-1;}

//19. Moving Average
//Buy: MA grows
//Sell: MA falls
if (iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,2)<iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,1)&&iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,1)<iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,0))
{f19=1;}
if (iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,2)>iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,1)&&iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,1)>iMA(NULL,pima,pimau,0,MODE_EMA,PRICE_CLOSE,0))
{f19=-1;}

//20. MACD (1)
//VERSION EXISTS, THAT THE SIGNAL TO BUY IS TRUE ONLY IF MACD<0, SIGNAL TO SELL - IF MACD>0
//Buy: MACD rises above the signal line
//Sell: MACD falls below the signal line
if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)<iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,1)&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)>=iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,0))
{f20=1;}
if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)>iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,1)&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)<=iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,0))
{f20=-1;}

//21. MACD (2)
//Buy: crossing 0 upwards
//Sell: crossing 0 downwards
if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)<0&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)>=0)
{f21=1;}
if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)>0&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)<=0)
{f21=-1;}


//22. Moving Average of Oscillator (MACD histogram) (1)
//Buy: histogram is below zero and changes falling direction into rising (5 columns are taken)
//Sell: histogram is above zero and changes its rising direction into falling (5 columns are taken)
if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
{f22=1;}
if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
{f22=-1;}

//23. Moving Average of Oscillator (MACD histogram) (2)
//To use the indicator it should be correlated with another trend indicator 
//Flag 23 is 1, when MACD histogram recommends to buy (i.e. histogram is sloping upwards)
//Flag 23 is -1, when MACD histogram recommends to sell (i.e. histogram is sloping downwards)
//3 columns are taken for calculation
if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
{f23=1;}
if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
{f23=-1;}

//24. Parabolic SAR
//Buy: Parabolic SAR crosses price downwards
//Sell: Parabolic SAR crosses price upwards
if(iSAR(NULL,pisar,isarstep,isarstop,1)>iClose(NULL,pisar2,1)&&iSAR(NULL,pisar,isarstep,isarstop,0)<=iClose(NULL,pisar2,0))
{f24=1;}
if(iSAR(NULL,pisar,isarstep,isarstop,1)<iClose(NULL,pisar2,1)&&iSAR(NULL,pisar,isarstep,isarstop,0)>=iClose(NULL,pisar2,0))
{f24=-1;}

//25. RSI
//Buy: crossing 30 upwards
//Sell: crossing 70 downwards
//TO FIGHT FALSE SIGNALS RECOMMENDED TO USE 2 PEAKS...
if(iRSI(NULL,pirsi,pirsiu,PRICE_CLOSE,1)<30&&iRSI(NULL,pirsi,pirsiu,PRICE_CLOSE,0)>=30)
{f25=1;}
if(iRSI(NULL,pirsi,pirsiu,PRICE_CLOSE,1)>70&&iRSI(NULL,pirsi,pirsiu,PRICE_CLOSE,0)<=70)
{f25=-1;}

//26. RVI
//RECOMMENDED TO USE WITH A TREND INDICATOR 
//Buy: main line (green) crosses signal (red) upwards
//Sell: main line (green) crosses signal (red) downwards
if(iRVI(NULL,pirvi,pirviu,MODE_MAIN,1)<iRVI(NULL,pirvi,pirviu,MODE_SIGNAL,1)&&iRVI(NULL,pirvi,pirviu,MODE_MAIN,0)>=iRVI(NULL,pirvi,pirviu,MODE_SIGNAL,0))
{f26=1;}
if(iRVI(NULL,pirvi,pirviu,MODE_MAIN,1)>iRVI(NULL,pirvi,pirviu,MODE_SIGNAL,1)&&iRVI(NULL,pirvi,pirviu,MODE_MAIN,0)<=iRVI(NULL,pirvi,pirviu,MODE_SIGNAL,0))
{f26=-1;}

//27. Standard Deviation
//Doesn't give independent signals. Is used to define volatility (trend strength).
//Principle: the trend must be strengthened. Together with this Standard Deviation goes up.
//Growth on 3 consecutive bars is analyzed
//Flag is 1 when Standard Deviation rises, 0 - when no growth, -1 - never.
if (iStdDev(NULL,pistd,pistdu,0,MODE_SMA,PRICE_CLOSE,2)<=iStdDev(NULL,pistd,pistdu,0,MODE_SMA,PRICE_CLOSE,1)&&iStdDev(NULL,pistd,pistdu,0,MODE_SMA,PRICE_CLOSE,1)<=iStdDev(NULL,pistd,pistdu,0,MODE_SMA,PRICE_CLOSE,0))
{f27=1;}

//28. Stochastic Oscillator (1)
//Buy: main lline rises above 20 after it fell below this point
//Sell: main line falls lower than 80 after it rose above this point
if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)<20&&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)>=20)
{f28=1;}
if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)>80&&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)<=80)
{f28=-1;}

//29. Stochastic Oscillator (2)
//Buy: main line goes above the signal line
//Sell: signal line goes above the main line
if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)<iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,1)&&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)>=iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,0))
{f29=1;}
if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)>iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,1)&&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)<=iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,0))
{f29=-1;}


//30. Williams Percent Range
//Buy: crossing -80 upwards
//Sell: crossing -20 downwards
if (iWPR(NULL,piwpr,piwprbar,1)<-80&&iWPR(NULL,piwpr,piwprbar,0)>=-80)
{f30=1;}
if (iWPR(NULL,piwpr,piwprbar,1)>-20&&iWPR(NULL,piwpr,piwprbar,0)<=-20)
{f30=-1;}

//----------End of strateguc block----------//


//----------Block of processing the strategy and placing the Main Flag----------
/*if(f8==1&&f21==1) //Set of conditions, providing which Buy is executed
flag=1;
if(f10==-1&&f21==-1) //Set of conditions, providing which Sell is executed
flag=-1;*/

//----------End of block of processing the strategy and placing the Main Flag----------

//----------Block of flag values diaplying----------
f[1]=f1;f[2]=f2;f[3]=f3;f[4]=f4;f[5]=f5;f[6]=f6;f[7]=f7;f[8]=f8;f[9]=f9;f[10]=f10;
f[11]=f11;f[12]=f12;f[13]=f13;f[14]=f14;f[15]=f15;f[16]=f16;f[17]=f17;f[18]=f18;f[19]=f19;f[20]=f20;
f[21]=f21;f[22]=f22;f[23]=f23;f[24]=f24;f[25]=f25;f[26]=f26;f[27]=f27;f[28]=f28;f[29]=f29;f[30]=f30;

// ----------------------- Kursy Bid/Ask --------------------------- START
//- Grupa opis wskazników - Kurs ASK
   ObjectCreate("Tabela kontrolnaKursAsk01", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaKursAsk01","Kurs ASK:               ... dzienny MAX:", sizeGroupTxt, "Tahoma", MarketTxtColor);
   ObjectSet("Tabela kontrolnaKursAsk01", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaKursAsk01", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolnaKursAsk01", OBJPROP_YDISTANCE, 21);
//
   ObjectCreate("Tabela kontrolnaKursAsk02", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaKursAsk02",DoubleToStr(Ask ,DigitsAfterDecimalPoints), sizeGroupTxt, "Tahoma", signalBuyColor);
   ObjectSet("Tabela kontrolnaKursAsk02", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaKursAsk02", OBJPROP_XDISTANCE, 63);
   ObjectSet("Tabela kontrolnaKursAsk02", OBJPROP_YDISTANCE, 21);
//
   ObjectCreate("Tabela kontrolnaKursAsk02-Max", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaKursAsk02-Max",DoubleToStr(highday ,DigitsAfterDecimalPoints), sizeGroupTxt, "Tahoma", signalBuyColor);
   ObjectSet("Tabela kontrolnaKursAsk02-Max", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaKursAsk02-Max", OBJPROP_XDISTANCE, 227);
   ObjectSet("Tabela kontrolnaKursAsk02-Max", OBJPROP_YDISTANCE, 21);
// - stop Kurs ASK

//- Grupa opis wskazników - Kurs BID
   ObjectCreate("Tabela kontrolnaKursBid01", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaKursBid01","Kurs BID :               ... dzienne MIN:", sizeGroupTxt, "Tahoma", MarketTxtColor);
   ObjectSet("Tabela kontrolnaKursBid01", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaKursBid01", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolnaKursBid01", OBJPROP_YDISTANCE, 33);
//
   ObjectCreate("Tabela kontrolnaKursBid02", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaKursBid02",DoubleToStr(Bid ,DigitsAfterDecimalPoints), sizeGroupTxt, "Tahoma", signalSellColor);
   ObjectSet("Tabela kontrolnaKursBid02", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaKursBid02", OBJPROP_XDISTANCE, 63);
   ObjectSet("Tabela kontrolnaKursBid02", OBJPROP_YDISTANCE, 33);
//
   ObjectCreate("Tabela kontrolnaKursBid02-MIN", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaKursBid02-MIN",DoubleToStr(lowday ,DigitsAfterDecimalPoints), sizeGroupTxt, "Tahoma", signalSellColor);
   ObjectSet("Tabela kontrolnaKursBid02-MIN", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaKursBid02-MIN", OBJPROP_XDISTANCE, 227);
   ObjectSet("Tabela kontrolnaKursBid02-MIN", OBJPROP_YDISTANCE, 33);
// - stop Kurs BID

// ----------------------- Kursy Bid/Ask --------------------------- STOP
// ----------------------- VOLUMES --------------------------- START

//- Grupa opis wskazników - start 03
   ObjectCreate("Tabela kontrolna03", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna03","[Volumes]: ", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna03", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna03", OBJPROP_XDISTANCE, 508);//156
   ObjectSet("Tabela kontrolna03", OBJPROP_YDISTANCE, 87);//21
// - stop 03
//- Grupa opis wskazników - start 04
   ObjectCreate("Tabela kontrolna04", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f2==1) {ObjectSetText("Tabela kontrolna04","Kupuj",sizeGroupTxt, "Tahoma Bold", signalBuyColor);}
   if (f2==-1) {ObjectSetText("Tabela kontrolna04","Sprzedaj",sizeGroupTxt, "Tahoma Bold", signalSellColor);}
   if (f2==0) {ObjectSetText("Tabela kontrolna04","Neutralnie",sizeGroupTxt, "Tahoma Bold", noSignalColor);}   
   ObjectSet("Tabela kontrolna04", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna04", OBJPROP_XDISTANCE, 577);//225
   ObjectSet("Tabela kontrolna04", OBJPROP_YDISTANCE, 87);//21
// - stop 04
//- opis wskaznika - start 2
   ObjectCreate("Tabela kontrolna3", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna3","Accumulation/Distribution - A/D ..", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna3", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna3", OBJPROP_XDISTANCE, 508);//156
   ObjectSet("Tabela kontrolna3", OBJPROP_YDISTANCE, 103);
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna4", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f2==1) {ObjectSetText("Tabela kontrolna4","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f2==-1) {ObjectSetText("Tabela kontrolna4","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f2==0) {ObjectSetText("Tabela kontrolna4","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna4", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna4", OBJPROP_XDISTANCE, 650);//294
   ObjectSet("Tabela kontrolna4", OBJPROP_YDISTANCE, 103);
//- stop 2
//- Separator START
   ObjectCreate("Tabela kontrolnaX", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaX","___________________________________________", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolnaX", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaX", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolnaX", OBJPROP_YDISTANCE, 39);
//- Separator STOP
// ----------------------- VOLUMES --------------------------- STOP




//- Grupa opis wskazników - start 05
   ObjectCreate("Tabela kontrolna05", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna05","Ichimoku Kinko Hyo ............. ", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna05", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna05", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna05", OBJPROP_YDISTANCE, 53);
// - stop 05
//- Grupa opis wskazników - start 06
   ObjectCreate("Tabela kontrolna06", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f15==1&&f16==1&&f17==1) {ObjectSetText("Tabela kontrolna06","Kupuj",sizeGroupTxt, "Tahoma Bold", signalBuyColor);}
   if (f15==-1&&f16==-1&&f17==-1) {ObjectSetText("Tabela kontrolna06","Sprzedaj",sizeGroupTxt, "Tahoma Bold", signalSellColor);}
   if (f15==0||f16==0||f17==0) {ObjectSetText("Tabela kontrolna06","Neutralnie",sizeGroupTxt, "Tahoma Bold", noSignalColor);}   
   ObjectSet("Tabela kontrolna06", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna06", OBJPROP_XDISTANCE, 175);
   ObjectSet("Tabela kontrolna06", OBJPROP_YDISTANCE, 53);
// - stop 06
//- opis wskaznika - start 
   ObjectCreate("Tabela kontrolna5", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna5","Cena przecina Senkou Span-B/Down Kumo ...", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna5", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna5", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna5", OBJPROP_YDISTANCE, 69);
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna6", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f15==1) {ObjectSetText("Tabela kontrolna6","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f15==-1) {ObjectSetText("Tabela kontrolna6","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f15==0) {ObjectSetText("Tabela kontrolna6","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna6", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna6", OBJPROP_XDISTANCE, 200);
   ObjectSet("Tabela kontrolna6", OBJPROP_YDISTANCE, 69);
//- stop 
//- opis wskaznika - start 
   ObjectCreate("Tabela kontrolna7", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna7","Tenkan-sen przecina Kijun-sen .....................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna7", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna7", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna7", OBJPROP_YDISTANCE, 85);
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna8", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f16==1) {ObjectSetText("Tabela kontrolna8","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f16==-1) {ObjectSetText("Tabela kontrolna8","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f16==0) {ObjectSetText("Tabela kontrolna8","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna8", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna8", OBJPROP_XDISTANCE, 200);
   ObjectSet("Tabela kontrolna8", OBJPROP_YDISTANCE, 85);
//- stop  
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna9", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna9","Chinkou Span przecina wykres ....................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna9", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna9", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna9", OBJPROP_YDISTANCE, 101);
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna10", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f17==1) {ObjectSetText("Tabela kontrolna10","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f17==-1) {ObjectSetText("Tabela kontrolna10","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f17==0) {ObjectSetText("Tabela kontrolna10","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna10", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna10", OBJPROP_XDISTANCE, 200);
   ObjectSet("Tabela kontrolna10", OBJPROP_YDISTANCE, 101);
//- stop 1
//- Separator START
   ObjectCreate("Tabela kontrolnaY", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaY","___________________________________________", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolnaY", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaY", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolnaY", OBJPROP_YDISTANCE, 105);
//- Separator STOP



//- Grupa opis wskazników - start 07
   ObjectCreate("Tabela kontrolna07", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna07","Bulls_Bears_Power + MACD ... ", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna07", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna07", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna07", OBJPROP_YDISTANCE, 119);
// - stop 07
//- Grupa opis wskazników - start 08
   ObjectCreate("Tabela kontrolna08", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f8==1&&f21==1) {ObjectSetText("Tabela kontrolna08","Kupuj",sizeGroupTxt, "Tahoma Bold", signalBuyColor);}
   if (f10==-1&&f21==-1) {ObjectSetText("Tabela kontrolna08","Sprzedaj",sizeGroupTxt, "Tahoma Bold", signalSellColor);}
   if (f8==0||f10==0||f21==0) {ObjectSetText("Tabela kontrolna08","Neutralnie",sizeGroupTxt, "Tahoma Bold", noSignalColor);}   
   ObjectSet("Tabela kontrolna08", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna08", OBJPROP_XDISTANCE, 175);
   ObjectSet("Tabela kontrolna08", OBJPROP_YDISTANCE, 119);
// - stop 08
//- Grupa opis wskazników - start 09
   ObjectCreate("Tabela kontrolna09", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna09","Signal line + MACD ...............", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna09", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna09", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna09", OBJPROP_YDISTANCE, 133);
// - stop 09
//- Grupa opis wskazników - start 10
   ObjectCreate("Tabela kontrolna010", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f20==1) {ObjectSetText("Tabela kontrolna010","Kupuj",sizeGroupTxt, "Tahoma Bold", signalBuyColor);}
   if (f20==-1) {ObjectSetText("Tabela kontrolna010","Sprzedaj",sizeGroupTxt, "Tahoma Bold", signalSellColor);}
   if (f20==0) {ObjectSetText("Tabela kontrolna010","Neutralnie",sizeGroupTxt, "Tahoma Bold", noSignalColor);}   
   ObjectSet("Tabela kontrolna010", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna010", OBJPROP_XDISTANCE, 175);
   ObjectSet("Tabela kontrolna010", OBJPROP_YDISTANCE, 133);
// - stop 10
//- Grupa opis wskazników - start 11
   ObjectCreate("Tabela kontrolna011", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna011","MACD Histogram ..................", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna011", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna011", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolna011", OBJPROP_YDISTANCE, 146);
// - stop 11
//- Grupa opis wskazników - start 012
   ObjectCreate("Tabela kontrolna012", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f22==1||f23==1) {ObjectSetText("Tabela kontrolna012","Kupuj",sizeGroupTxt, "Tahoma Bold", signalBuyColor);}
   if (f22==-1||f23==-1) {ObjectSetText("Tabela kontrolna012","Sprzedaj",sizeGroupTxt, "Tahoma Bold", signalSellColor);}
   if (f22==0||f23==0) {ObjectSetText("Tabela kontrolna012","Neutralnie",sizeGroupTxt, "Tahoma Bold", noSignalColor);}   
   ObjectSet("Tabela kontrolna012", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna012", OBJPROP_XDISTANCE, 175);
   ObjectSet("Tabela kontrolna012", OBJPROP_YDISTANCE, 146);
// - stop 012
//- Separator START
   ObjectCreate("Tabela kontrolnaZ", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaZ","___________________________________________", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolnaZ", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaZ", OBJPROP_XDISTANCE, 5);
   ObjectSet("Tabela kontrolnaZ", OBJPROP_YDISTANCE, 150);
//- Separator STOP



//- Grupa opis wskazników - start 013
   ObjectCreate("Tabela kontrolna013", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna013","[WskaŸniki trendu (6)]: ", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna013", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna013", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna013", OBJPROP_YDISTANCE, 7);
// - stop 013


//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna11", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna11","Average Direct. Move. Index (ADX) ...", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna11", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna11", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna11", OBJPROP_YDISTANCE, 23); //37
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna12", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f5==1) {ObjectSetText("Tabela kontrolna12","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f5==-1) {ObjectSetText("Tabela kontrolna12","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f5==0) {ObjectSetText("Tabela kontrolna12","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna12", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna12", OBJPROP_XDISTANCE, 487);
   ObjectSet("Tabela kontrolna12", OBJPROP_YDISTANCE, 23);
//- stop 1
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna13", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna13","Moving Average .............................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna13", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna13", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna13", OBJPROP_YDISTANCE, 39);//53
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna14", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f19==1) {ObjectSetText("Tabela kontrolna14","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f19==-1) {ObjectSetText("Tabela kontrolna14","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f19==0) {ObjectSetText("Tabela kontrolna14","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna14", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna14", OBJPROP_XDISTANCE, 487);
   ObjectSet("Tabela kontrolna14", OBJPROP_YDISTANCE, 39);//53
//- stop 1
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna15", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna15","Bollinger Bands ................................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna15", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna15", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna15", OBJPROP_YDISTANCE, 55);//69
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna16", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f9==1) {ObjectSetText("Tabela kontrolna16","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f9==-1) {ObjectSetText("Tabela kontrolna16","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f9==0) {ObjectSetText("Tabela kontrolna16","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna16", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna16", OBJPROP_XDISTANCE, 487);
   ObjectSet("Tabela kontrolna16", OBJPROP_YDISTANCE, 55);//69
//- stop 1
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna17", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna17","Commodity Channel Index ...............", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna17", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna17", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna17", OBJPROP_YDISTANCE, 71);//85
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna18", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f11==1) {ObjectSetText("Tabela kontrolna18","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f11==-1) {ObjectSetText("Tabela kontrolna18","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f11==0) {ObjectSetText("Tabela kontrolna18","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna18", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna18", OBJPROP_XDISTANCE, 487);
   ObjectSet("Tabela kontrolna18", OBJPROP_YDISTANCE, 71);//85
//- stop 1
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna19", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna19","Parabolic SAR .................................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna19", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna19", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna19", OBJPROP_YDISTANCE, 87);//101
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna20", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f24==1) {ObjectSetText("Tabela kontrolna20","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f24==-1) {ObjectSetText("Tabela kontrolna20","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f24==0) {ObjectSetText("Tabela kontrolna20","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna20", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna20", OBJPROP_XDISTANCE, 487);
   ObjectSet("Tabela kontrolna20", OBJPROP_YDISTANCE, 87);//101
//- stop 1
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna21", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna21","Standard Deviation ..........................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna21", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna21", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna21", OBJPROP_YDISTANCE, 103);//117
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna22", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f27==1) {ObjectSetText("Tabela kontrolna22","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   //if (f27==-1) {ObjectSetText("Tabela kontrolna22","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f27==0) {ObjectSetText("Tabela kontrolna22","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna22", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna22", OBJPROP_XDISTANCE, 487);
   ObjectSet("Tabela kontrolna22", OBJPROP_YDISTANCE, 103);//117
//- stop 1

//- Separator START
   ObjectCreate("Tabela kontrolnaZ2", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaZ2","__________________________", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolnaZ2", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaZ2", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolnaZ2", OBJPROP_YDISTANCE, 107);//121
//- Separator STOP









//- Grupa opis wskazników - start 01
   ObjectCreate("Tabela kontrolna01", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna01","[Bill Williams (2)]: ", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna01", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna01", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolna01", OBJPROP_YDISTANCE, 7);//21
// - stop 01
//- Grupa opis wskazników - start 02
   ObjectCreate("Tabela kontrolna02", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f1==1&&f4==1) {ObjectSetText("Tabela kontrolna02","Kupuj",sizeGroupTxt, "Tahoma Bold", signalBuyColor);}
   if (f1==-1&&f4==-1) {ObjectSetText("Tabela kontrolna02","Sprzedaj",sizeGroupTxt, "Tahoma Bold", signalSellColor);}
   if (f1==0||f4==0) {ObjectSetText("Tabela kontrolna02","Neutralnie",sizeGroupTxt, "Tahoma Bold", noSignalColor);}   
   ObjectSet("Tabela kontrolna02", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna02", OBJPROP_XDISTANCE, 605);
   ObjectSet("Tabela kontrolna02", OBJPROP_YDISTANCE, 7);//21
// - stop 02
//- opis wskaznika - start 1
   ObjectCreate("Tabela kontrolna1", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna1","Acceleration/Deceleration — AC ..", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna1", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna1", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolna1", OBJPROP_YDISTANCE, 23);//37
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna2", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f1==1) {ObjectSetText("Tabela kontrolna2","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f1==-1) {ObjectSetText("Tabela kontrolna2","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f1==0) {ObjectSetText("Tabela kontrolna2","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna2", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna2", OBJPROP_XDISTANCE, 650);
   ObjectSet("Tabela kontrolna2", OBJPROP_YDISTANCE, 23);//37
//- stop 1
//- opis wskaznika - start 23
   ObjectCreate("Tabela kontrolna23", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna23","Alligator & Fractals +", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna23", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna23", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolna23", OBJPROP_YDISTANCE, 39);//53
   ObjectCreate("Tabela kontrolna23a", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna23a","+ Gator Oscillator .....................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna23a", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna23a", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolna23a", OBJPROP_YDISTANCE, 55);//69
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna24", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f4==1) {ObjectSetText("Tabela kontrolna24","[K]",sizeTxt, "Tahoma Bold", signalBuyColor);}
   if (f4==-1){ObjectSetText("Tabela kontrolna24","[S]",sizeTxt, "Tahoma Bold", signalSellColor);}
   if (f4==0) {ObjectSetText("Tabela kontrolna24","[N]",sizeTxt, "Tahoma Bold", noSignalColor);}
   ObjectSet("Tabela kontrolna24", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna24", OBJPROP_XDISTANCE, 650);
   ObjectSet("Tabela kontrolna24", OBJPROP_YDISTANCE, 55);//69
//- stop 23
//- Separator START
   ObjectCreate("Tabela kontrolnaZ3", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaZ3","______________________", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolnaZ3", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaZ3", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolnaZ3", OBJPROP_YDISTANCE, 59);//73
//- Separator STOP





//- Grupa opis wskazników - start 015
   ObjectCreate("Tabela kontrolna015", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna015","[Oscylatory (9)]: ", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolna015", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna015", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna015", OBJPROP_YDISTANCE, 7);//21
// - stop 015

//- opis wskaznika - start 25/26
   ObjectCreate("Tabela kontrolna25", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna25","Average True Range - ATR .....", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna25", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna25", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna25", OBJPROP_YDISTANCE, 23);//37
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna26", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f6==1) {ObjectSetText("Tabela kontrolna26","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f6==-1) {ObjectSetText("Tabela kontrolna26","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f6==0) {ObjectSetText("Tabela kontrolna26","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna26", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna26", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna26", OBJPROP_YDISTANCE, 23);//37
//- stop 25/26
//- opis wskaznika - start 27/28
   ObjectCreate("Tabela kontrolna27", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna27","Awesome Oscillator ..............", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna27", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna27", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna27", OBJPROP_YDISTANCE, 39);//53
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna28", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f7==1) {ObjectSetText("Tabela kontrolna28","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f7==-1) {ObjectSetText("Tabela kontrolna28","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f7==0) {ObjectSetText("Tabela kontrolna28","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna28", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna28", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna28", OBJPROP_YDISTANCE, 39);//53
//- stop 27/28
//- opis wskaznika - start 29/30
   ObjectCreate("Tabela kontrolna29", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna29","DeMarker ............................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna29", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna29", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna29", OBJPROP_YDISTANCE, 55);//69
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna030", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f12==1) {ObjectSetText("Tabela kontrolna030","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f12==-1) {ObjectSetText("Tabela kontrolna030","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f12==0) {ObjectSetText("Tabela kontrolna030","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna030", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna030", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna030", OBJPROP_YDISTANCE, 55);//69
//- stop 29/30
//- opis wskaznika - start 30/31
   ObjectCreate("Tabela kontrolna30", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna30","Envelopes ...........................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna30", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna30", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna30", OBJPROP_YDISTANCE, 71);//85
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna31", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f13==1) {ObjectSetText("Tabela kontrolna31","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f13==-1) {ObjectSetText("Tabela kontrolna31","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f13==0) {ObjectSetText("Tabela kontrolna31","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna31", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna31", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna31", OBJPROP_YDISTANCE, 71);//85
//- stop 30/31
//- opis wskaznika - start 32/33
   ObjectCreate("Tabela kontrolna32", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna32","Force Index ..........................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna32", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna32", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna32", OBJPROP_YDISTANCE, 87);//101
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna33", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f14==1) {ObjectSetText("Tabela kontrolna33","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f14==-1) {ObjectSetText("Tabela kontrolna33","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f14==0) {ObjectSetText("Tabela kontrolna33","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna33", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna33", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna33", OBJPROP_YDISTANCE, 87);//101
//- stop 32/33
//- opis wskaznika - start 34/35
   ObjectCreate("Tabela kontrolna34", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna34","Money Flow Index - MFI ........", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna34", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna34", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna34", OBJPROP_YDISTANCE, 103);//117
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna35", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f18==1) {ObjectSetText("Tabela kontrolna35","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f18==-1) {ObjectSetText("Tabela kontrolna35","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f18==0) {ObjectSetText("Tabela kontrolna35","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna35", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna35", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna35", OBJPROP_YDISTANCE, 103);//117
//- stop 34/35
//- opis wskaznika - start 36/37
   ObjectCreate("Tabela kontrolna36", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna36","Relative Strength Index - RSI ..", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna36", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna36", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna36", OBJPROP_YDISTANCE, 119);//133
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna37", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f25==1) {ObjectSetText("Tabela kontrolna37","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f25==-1) {ObjectSetText("Tabela kontrolna37","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f25==0) {ObjectSetText("Tabela kontrolna37","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna37", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna37", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna37", OBJPROP_YDISTANCE, 119);//133
//- stop 36/37
//- opis wskaznika - start 38/39
   ObjectCreate("Tabela kontrolna38", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna38","Stochastic Oscillator ................", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna38", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna38", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna38", OBJPROP_YDISTANCE, 135);//149
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna39", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f28==1&&f29==1) {ObjectSetText("Tabela kontrolna39","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f28==-1&&f29==-1) {ObjectSetText("Tabela kontrolna39","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f28==0||f29==0) {ObjectSetText("Tabela kontrolna39","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna39", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna39", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna39", OBJPROP_YDISTANCE, 135);//149
//- stop 38/39
//- opis wskaznika - start 40/41
   ObjectCreate("Tabela kontrolna40", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna40","Williams Percent Range - WPR%", sizeTxt, "Tahoma", textColor);
   ObjectSet("Tabela kontrolna40", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna40", OBJPROP_XDISTANCE, 673);
   ObjectSet("Tabela kontrolna40", OBJPROP_YDISTANCE, 151);//165
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna41", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   if (f30==1) {ObjectSetText("Tabela kontrolna41","[K]",sizeTxt, "Tahoma", signalBuyColor);}
   if (f30==-1) {ObjectSetText("Tabela kontrolna41","[S]",sizeTxt, "Tahoma", signalSellColor);}
   if (f30==0) {ObjectSetText("Tabela kontrolna41","[N]",sizeTxt, "Tahoma", noSignalColor);}
   ObjectSet("Tabela kontrolna41", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna41", OBJPROP_XDISTANCE, 810);
   ObjectSet("Tabela kontrolna41", OBJPROP_YDISTANCE, 151);//165
//- stop 40/41
//- Separator START
   ObjectCreate("Tabela kontrolnaZ4", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolnaZ4","______________________", sizeGroupTxt, "Tahoma", GroupTxtColor);
   ObjectSet("Tabela kontrolnaZ4", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolnaZ4", OBJPROP_XDISTANCE, 508); //673
   ObjectSet("Tabela kontrolnaZ4", OBJPROP_YDISTANCE, 107); //155
//- Separator STOP

// Buy SWAP / Sell SWAP
//- Grupa opis wskazników - start 42
   ObjectCreate("Tabela kontrolna42", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna42","Buy SWAP....", sizeGroupTxt, "Tahoma", MarketTxtColor);
   ObjectSet("Tabela kontrolna42", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna42", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna42", OBJPROP_YDISTANCE, 133);
// - stop 42
//- Grupa opis wskazników - start 031
   ObjectCreate("Tabela kontrolna031", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna031",DoubleToStr(swaplong ,2),sizeGroupTxt, "Tahoma Bold", signalBuyColor);
   ObjectSet("Tabela kontrolna031", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna031", OBJPROP_XDISTANCE, 400);
   ObjectSet("Tabela kontrolna031", OBJPROP_YDISTANCE, 133);
// - stop 031
//- Grupa opis wskazników - start 032
   ObjectCreate("Tabela kontrolna032", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna032","Sell SWAP.....", sizeGroupTxt, "Tahoma", MarketTxtColor);
   ObjectSet("Tabela kontrolna032", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna032", OBJPROP_XDISTANCE, 320);
   ObjectSet("Tabela kontrolna032", OBJPROP_YDISTANCE, 146);
// - stop 032
//- Grupa opis wskazników - start 033
   ObjectCreate("Tabela kontrolna033", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna033",DoubleToStr(swapshort ,2),sizeGroupTxt, "Tahoma", signalSellColor);
   ObjectSet("Tabela kontrolna033", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna033", OBJPROP_XDISTANCE, 400);
   ObjectSet("Tabela kontrolna033", OBJPROP_YDISTANCE, 146);
// - stop 012

// Spread
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna43", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna43","Spread ..............     (pip/s)", sizeGroupTxt, "Tahoma", MarketTxtColor);
   ObjectSet("Tabela kontrolna43", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna43", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolna43", OBJPROP_YDISTANCE, 133);//101
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna44", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna44",DoubleToStr(spread ,0),sizeGroupTxt, "Tahoma", noSignalColor);
   ObjectSet("Tabela kontrolna44", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna44", OBJPROP_XDISTANCE, 610);
   ObjectSet("Tabela kontrolna44", OBJPROP_YDISTANCE, 133);//101
//- stop 1

// Depozyt
//- opis wskaznika - start  
   ObjectCreate("Tabela kontrolna45", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna45","Depozyt (0.01) ...            $", sizeGroupTxt, "Tahoma", MarketTxtColor);
   ObjectSet("Tabela kontrolna45", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna45", OBJPROP_XDISTANCE, 508);
   ObjectSet("Tabela kontrolna45", OBJPROP_YDISTANCE, 146);//117
//- wartosc wskaznika
   ObjectCreate("Tabela kontrolna46", OBJ_LABEL, WindowFind("Tabela kontrolna ("+Symbol()+")"), 0, 0);
   ObjectSetText("Tabela kontrolna46",DoubleToStr(MARGINREQUIRED ,2),sizeGroupTxt, "Tahoma", noSignalColor); 
   ObjectSet("Tabela kontrolna46", OBJPROP_CORNER, 0);
   ObjectSet("Tabela kontrolna46", OBJPROP_XDISTANCE, 610);
   ObjectSet("Tabela kontrolna46", OBJPROP_YDISTANCE, 146);//117
//- stop 1


  }
//+------------------------------------------------------------------+
//----
   return(0);
  }