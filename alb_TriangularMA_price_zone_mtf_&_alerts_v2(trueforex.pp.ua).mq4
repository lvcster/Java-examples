//+------------------------------------------------------------------+
//|                                alb - TriangularMA price zone.mq4 |
//|                                                           mladen |
//|                                                                  |
//| original idea and first implementation                           |
//| for this indicator by mrtools                                    |
//+------------------------------------------------------------------+
#property copyright "mrtools & mladen"
#property link      "mrtools & mladen"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 LimeGreen

//
//
//
//
//
extern string TimeFrame             = "current time frame";
extern int    swingCount            = 5;
extern int    ShortLimit            = 10;
extern int    LongLimit             = 20;
extern int    CfbNormLength         = 50;
extern int    CfbDepth              = 1;
extern int    CfbPrice              = PRICE_MEDIAN;
extern int    CfbSmooth             = 8;
extern int    CfbResultSmooth       = 5;
extern double CfbResultSmoothPhase  = 0.0;
extern bool   CfbResultSmoothDouble = true;
extern double SmoothPhase           = 0.0;
extern bool   SmoothDouble          = true;
extern int    Price                 = PRICE_MEDIAN;
extern double speed                 = 1.0;
extern double UpDeviation           = 1.8;
extern double DnDeviation           = 1.8;
extern bool   Interpolate           = true;

extern bool   alertsOn              = true;
extern bool   alertsOnCurrent       = false;
extern bool   alertsOnHighLow       = true;
extern bool   alertsMessage         = true;
extern bool   alertsSound           = false;
extern bool   alertsEmail           = false;


//
//
//
//
//

double buffer1[];
double buffer2[];
double swingBuffer[];
double trend[];
double cfb[];

double rangePeriod;


string indicatorFileName;
bool   calculateTMA;
bool   returnBars;
int    timeFrame;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

int init()
{
   IndicatorBuffers(5);
   SetIndexBuffer(0,buffer1);
   SetIndexBuffer(1,buffer2);
   SetIndexBuffer(2,swingBuffer);
   SetIndexBuffer(3,cfb);
   SetIndexBuffer(4,trend);

      //
      //
      //
      //
      //
   
    indicatorFileName = WindowExpertName();
    returnBars        = TimeFrame=="returnBars";   if (returnBars)     return(0);
    calculateTMA      = TimeFrame=="calculateTMA"; if (calculateTMA) return(0);
    timeFrame         = stringToTimeFrame(TimeFrame);
      
    IndicatorShortName(timeFrameToString(timeFrame)+"alb TMA bands");
      
      
   return(0);
}


int deinit() { return(0); }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,j,n,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-1,Bars-counted_bars+4*rangePeriod);
           if (returnBars)  { buffer1[0] = limit+1; return(0); }

   //
   //
   //
   //
   //
      if (calculateTMA || timeFrame==Period())
      {
   
      for(i=limit, r=Bars-i-1; i>=0; i--, r++)
      {
       cfb[i] = iDSmooth(Bars,iCfb(Bars,iMA(NULL,0,1,0,MODE_SMA,CfbPrice,i),CfbDepth,CfbSmooth,r),CfbResultSmooth,CfbResultSmoothPhase,CfbResultSmoothDouble,r);
         
         double cfbMax = cfb[i];
         double cfbMin = cfb[i];
         for (int k=1; k<CfbNormLength && (i+k)<Bars; k++ )
         {
                cfbMax = MathMax(cfb[i+k],cfbMax);
                cfbMin = MathMin(cfb[i+k],cfbMin);
         }
         double denominator = cfbMax-cfbMin;
         if (denominator> 0)
         double ratio = (cfb[i]-cfbMin)/denominator;
         else      ratio = 0.5;                 
   
         rangePeriod = MathCeil(ShortLimit+ratio*(LongLimit-ShortLimit));
         int swing   = 0;
         
         if (High[i]>High[i+1] && High[i+1]>High[i+2] && Low[i+2] < Low[i+3] && Low[i+3] < Low[i+4]) swing = -1;
         if (Low[i] < Low[i+1] && Low[i+1] < Low[i+2] && High[i+2]>High[i+3] && High[i+3]>High[i+4]) swing =  1;
         
         swingBuffer[i] = swing;
         
         for (k=i,n=0; (k<Bars) && (n<swingCount); k++) if(swingBuffer[k]!=0) n++;
         int HalfLength = MathMax(MathRound((k-i)/swingCount/speed),1);

         //
         //
         //
         //
         //

         double sum   = (HalfLength+1)*iMA(NULL,0,1,0,MODE_SMA,Price,i);
         double sumw  = (HalfLength+1);
            for(j=1, k=HalfLength; j<=HalfLength; j++, k--)
            {
               sum  += k*iMA(NULL,0,1,0,MODE_SMA,Price,i+j);
               sumw += k;
               if (j<=i)
               {
                  sum  += k*iMA(NULL,0,1,0,MODE_SMA,Price,i-j);
                  sumw += k;
               }
            }
         double tma    = sum/sumw;
         double range  = CalculateRange(rangePeriod,i);

         //
         //
         //
         //
         //
         
      buffer1[i] = tma+UpDeviation*range;
      buffer2[i] = tma-DnDeviation*range;
      
      
      trend[i] = 0;                     
            if (alertsOnHighLow)       
            {
               if (High[i] > buffer1[i]) trend[i] = -1;
               if (Low[i]  < buffer2[i]) trend[i] =  1;
            }
            else
            {
               if (Close[i] > buffer1[i]) trend[i] = -1;
               if (Close[i] < buffer2[i]) trend[i] =  1;
            }
      }
      if (!calculateTMA) manageAlerts();
      return(0);            
   }
      
   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for(i=limit; i>=0; i--)
   {
      int y         = iBarShift(NULL,timeFrame,Time[i]);
      buffer1[i]    = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",swingCount,ShortLimit,LongLimit,CfbNormLength,CfbDepth,CfbPrice,CfbSmooth,CfbResultSmooth,CfbResultSmoothPhase,CfbResultSmoothDouble,SmoothPhase,SmoothDouble,Price,speed,UpDeviation,DnDeviation,0,y);
      buffer2[i]    = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",swingCount,ShortLimit,LongLimit,CfbNormLength,CfbDepth,CfbPrice,CfbSmooth,CfbResultSmooth,CfbResultSmoothPhase,CfbResultSmoothDouble,SmoothPhase,SmoothDouble,Price,speed,UpDeviation,DnDeviation,1,y);
      swingBuffer[i]= iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",swingCount,ShortLimit,LongLimit,CfbNormLength,CfbDepth,CfbPrice,CfbSmooth,CfbResultSmooth,CfbResultSmoothPhase,CfbResultSmoothDouble,SmoothPhase,SmoothDouble,Price,speed,UpDeviation,DnDeviation,2,y);
      trend[i]      = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",swingCount,ShortLimit,LongLimit,CfbNormLength,CfbDepth,CfbPrice,CfbSmooth,CfbResultSmooth,CfbResultSmoothPhase,CfbResultSmoothDouble,SmoothPhase,SmoothDouble,Price,speed,UpDeviation,DnDeviation,4,y);

      //
      //
      //
      //
      //
       
      if (timeFrame <= Period() || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;
      if (!Interpolate) continue;

      //
      //
      //
      //
      //

      datetime time = iTime(NULL,timeFrame,y);
         for(int nn = 1; i+n < Bars && Time[i+nn] >= time; nn++) continue;	
         for(k = 1; k < nn; k++)
         {
            buffer1[i+k]     = buffer1[i]     + (buffer1[i+nn]    - buffer1[i])*k/nn;
            buffer2[i+k]     = buffer2[i]     + (buffer2[i+nn]    - buffer2[i])*k/nn;
            swingBuffer[i+k] = swingBuffer[i] +( swingBuffer[i+nn]- swingBuffer[i])*k/nn;
         }               
   }

   //
   //
   //
   //
   //
      
   manageAlerts();
   return(0);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] == 1) doAlert(whichBar,"up");
         if (trend[whichBar] ==-1) doAlert(whichBar,"down");
      }         
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," "+timeFrameToString(timeFrame)+" TMA bands price penetrated ",doWhat," band");
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"TMA bands "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = StringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int char = StringGetChar(s, length);
         if((char > 96 && char < 123) || (char > 223 && char < 256))
                     s = StringSetChar(s, length, char - 32);
         else if(char > -33 && char < 0)
                     s = StringSetChar(s, length, char + 224);
   }
   return(s);
}   
 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double CalculateRange(int HalfLength,int i)
{
   int j,k;
   double lsum   = (HalfLength+1)*iDSmooth(iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i), rangePeriod,SmoothPhase,SmoothDouble,i,20);
   double hsum   = (HalfLength+1)*iDSmooth(iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i),rangePeriod,SmoothPhase,SmoothDouble,i,40);
   double sumw   = (HalfLength+1);
   
   //
   //
   //
   //
   //
      
   for(j=1, k=HalfLength; j<=HalfLength; j++, k--)
   {
      lsum += k*iDSmooth(iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i+j), rangePeriod,SmoothPhase,SmoothDouble,i+j,20);
      hsum += k*iDSmooth(iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i+j),rangePeriod,SmoothPhase,SmoothDouble,i+j,40);
      sumw += k;

      if (j<=i)
      {
         lsum  += k*iDSmooth(iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i-j), rangePeriod,SmoothPhase,SmoothDouble,i-j,20);
         hsum  += k*iDSmooth(iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i-j),rangePeriod,SmoothPhase,SmoothDouble,i-j,40);
         sumw += k;
      }
   }
   return (hsum/sumw - lsum/sumw);
}



int    Depths[] = {2,3,4,6,8,12,16,24,32,48,64,96,128,192};
double workCfb[][28];

//
//
//
//
//

double iCfb(int totalBars, double price, int depth, int smooth, int i)
{
   if (ArrayRange(workCfb,0) != totalBars) ArrayResize(workCfb,totalBars);
         
   //
   //
   //
   //
   //

   double suma     = 0;
   double sumb     = 0;
   double cfb      = 0;
   double evenCoef = 1;
   double oddCoef  = 1;
   double avg      = 0;
         
      if (i>=smooth)
         for (int k=depth-1; k>=0; k--)
         {
            workCfb[i][k]    = iCfbFunc(totalBars,price,i,Depths[k],k);
            workCfb[i][k+14] = workCfb[i-1][k+14] + (workCfb[i][k]-workCfb[i-smooth][k])/smooth;

                  if ((k%2)==0)
                        { avg = oddCoef  * workCfb[i][k+14]; oddCoef  = oddCoef  * (1 - avg); }
                  else  { avg = evenCoef * workCfb[i][k+14]; evenCoef = evenCoef * (1 - avg); }
               
               suma += avg*avg*Depths[k];
               sumb += avg;
         }
      else for (k=depth-1; k>=0; k--) { workCfb[i][k] = 0; workCfb[i][k+14] = 0; }            

   //
   //
   //
   //
   //

   if (sumb != 0) cfb = suma/sumb;
   return(cfb);
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

double  workCfbFunc[][70];
#define _prices 0
#define _roc    1
#define _value1 2
#define _value2 3
#define _value3 4

//
//
//
//

double iCfbFunc(int totalBars, double price, int r, int depth, int k)
{
   k *= 5;
      if (ArrayRange(workCfbFunc,0) != totalBars) ArrayResize(workCfbFunc,totalBars);
      if (r<=(depth+1))
      {
         workCfbFunc[r][k+_prices] = 0;
         workCfbFunc[r][k+_roc]    = 0;
         workCfbFunc[r][k+_value1] = 0;
         workCfbFunc[r][k+_value2] = 0;
         workCfbFunc[r][k+_value3] = 0;
         return(0);
      }         
      workCfbFunc[r][k+_prices] = price; 

   //
   //
   //
   //
   //

      workCfbFunc[r][k+_roc]    = MathAbs(workCfbFunc[r][k+_prices] - workCfbFunc[r-1][k+_prices]);
      workCfbFunc[r][k+_value1] = workCfbFunc[r-1][k+_value1] - workCfbFunc[r-depth][k+_roc] + workCfbFunc[r][k+_roc];
      workCfbFunc[r][k+_value2] = workCfbFunc[r-1][k+_value2] - workCfbFunc[r-1][k+_value1] + workCfbFunc[r][k+_roc]*depth;
      workCfbFunc[r][k+_value3] = workCfbFunc[r-1][k+_value3] - workCfbFunc[r-1-depth][k+_prices] + workCfbFunc[r-1][k+_prices];
   
      double dividend = MathAbs(depth*workCfbFunc[r][k+_prices]-workCfbFunc[r][k+_value3]);

      //
      //
      //
      //
      //
         
   if (workCfbFunc[r][k+_value2] != 0)
         return( dividend / workCfbFunc[r][k+_value2]);
   else  return(0.00);            
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//



double wrk[][60];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iDSmooth(double price, double length, double phase, bool isDouble, int i, int s=0)
{
   if (isDouble)
         return (iSmooth(iSmooth(price,MathSqrt(length),phase,i,s),MathSqrt(length),phase,i,s+10));
   else  return (iSmooth(price,length,phase,i,s));
}

//
//
//
//
//

double iSmooth(double price, double length, double phase, int i, int s=0)
{
   if (length <=1) return(price);
   if (ArrayRange(wrk,0) != Bars) ArrayResize(wrk,Bars);
   
   int r = Bars-i-1; 
      if (r==0) { for(int k=0; k<7; k++) wrk[r][k+s]=price; for(; k<10; k++) wrk[r][k+s]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax+s];
      double del2   = price - wrk[r-1][bsmin+s];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = MathMin(r,10);
	
         wrk[r][volty+s] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty+s] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty+s] = MathAbs(del2); 
         wrk[r][vsum+s] =	wrk[r-1][vsum+s] + (wrk[r][volty+s]-wrk[r-forBar][volty+s])*div;
         
         //
         //
         //
         //
         //
   
         wrk[r][avolty+s] = wrk[r-1][avolty+s]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum+s]-wrk[r-1][avolty+s]);
            if (wrk[r][avolty+s] > 0)
               double dVolty = wrk[r][volty+s]/wrk[r][avolty+s]; else dVolty = 0;   
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax+s] = price; else wrk[r][bsmax+s] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin+s] = price; else wrk[r][bsmin+s] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0+s] = price + alpha*(wrk[r-1][0+s]-price);
         wrk[r][1+s] = (price - wrk[r][0+s])*(1-beta) + beta*wrk[r-1][1+s];
         wrk[r][2+s] = (wrk[r][0+s] + R*wrk[r][1+s]);
         wrk[r][3+s] = (wrk[r][2+s] - wrk[r-1][4+s])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3+s];
         wrk[r][4+s] = (wrk[r-1][4+s] + wrk[r][3+s]); 

   //
   //
   //
   //
   //

   return(wrk[r][4+s]);
}