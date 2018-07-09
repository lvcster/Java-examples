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
#property indicator_color1 LimeGreen
#property indicator_color2 Red

//
//
//
//
//
extern string TimeFrame    = "current time frame";
extern int    swingCount   = 5;
extern int    rangePeriod  = 5;
extern int    Price        = PRICE_MEDIAN;
extern double speed        = 1.0;
extern double Deviation    = 1.8;
extern double SmoothLength = 4;
extern double SmoothPhase  = 0;

//
//
//
//
//

double buffer1[];
double buffer2[];
double swingBuffer[];

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
   IndicatorBuffers(3);
   SetIndexBuffer(0,buffer1);
   SetIndexBuffer(1,buffer2);
   SetIndexBuffer(2,swingBuffer);
   IndicatorDigits(Digits);

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
   int i,j,k,n,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-1,Bars-counted_bars+4*rangePeriod);

   //
   //
   //
   //
   //
   
   for (i=limit; i>=0; i--)
   {
      int swing = 0;
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
         double tma    = iSmooth(sum/sumw,SmoothLength,SmoothPhase,i);
         double range  = CalculateRange(rangePeriod,i);

         //
         //
         //
         //
         //
         
      buffer1[i] = tma+Deviation*range;
      buffer2[i] = tma-Deviation*range;
   }
   return(0);
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
   double lsum   = (HalfLength+1)*iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i);
   double hsum   = (HalfLength+1)*iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i);
   double sumw   = (HalfLength+1);
   
   //
   //
   //
   //
   //
      
   for(j=1, k=HalfLength; j<=HalfLength; j++, k--)
   {
      lsum += k*iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i+j);
      hsum += k*iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i+j);
      sumw += k;

      if (j<=i)
      {
         lsum  += k*iMA(NULL,0,1,0,MODE_SMA,PRICE_LOW,i-j);
         hsum  += k*iMA(NULL,0,1,0,MODE_SMA,PRICE_HIGH,i-j);
         sumw += k;
      }
   }
   return (hsum/sumw - lsum/sumw);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double wrk[][10];

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