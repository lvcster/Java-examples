//+------------------------------------------------------------------+
//|                                                    iFractals.mq4 |
//|                                        Copyright © 2008, lotos4u |
//|                                                lotos4u@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, lotos4u"
#property link      "lotos4u@gmail.com"

#property indicator_chart_window
#property indicator_buffers 6

#property indicator_width1 4
#property indicator_width2 4
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 2
#property indicator_width6 2

#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Gold
#property indicator_color4 Gold
#property indicator_color5 White
#property indicator_color6 White

extern int LeftBars  = 3;
extern int RightBars = 3;

double LineUpBuffer1[];
double LineDownBuffer2[];
double ArrowUpBuffer3[];
double ArrowDownBuffer4[];
double ArrowBreakUpBuffer5[];
double ArrowBreakDownBuffer6[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE);
   SetIndexArrow(0, 158);
   SetIndexBuffer(0, LineUpBuffer1);
   SetIndexEmptyValue(0, 0.0);
   SetIndexLabel(0, "Фрактальное сопротивление");
   
   SetIndexStyle(1, DRAW_LINE);
   SetIndexArrow(1, 158);
   SetIndexBuffer(1, LineDownBuffer2);
   SetIndexEmptyValue(1, 0.0);
   SetIndexLabel(1, "Фрактальная поддержка");

   SetIndexStyle(2, DRAW_ARROW);
   SetIndexArrow(2, 119);
   //SetIndexArrow(2, 217);
   SetIndexBuffer(2, ArrowUpBuffer3);
   SetIndexEmptyValue(2, 0.0);
   SetIndexLabel(2, "Фрактал ВЕРХ");
   
   SetIndexStyle(3, DRAW_ARROW);
   SetIndexArrow(3, 119);
   //SetIndexArrow(3, 218);
   SetIndexBuffer(3, ArrowDownBuffer4);
   SetIndexEmptyValue(3, 0.0);
   SetIndexLabel(3, "Фрактал ВНИЗ");

   SetIndexStyle(4, DRAW_ARROW);
   SetIndexArrow(4, 119);
   //SetIndexArrow(4, 217);
   SetIndexBuffer(4, ArrowBreakUpBuffer5);
   SetIndexEmptyValue(4, 0.0);
   SetIndexLabel(4, "Пробой ВВЕРХ");
   
   SetIndexStyle(5, DRAW_ARROW);
   SetIndexArrow(5, 119);
   //SetIndexArrow(5, 218);
   SetIndexBuffer(5, ArrowBreakDownBuffer6);
   SetIndexEmptyValue(5, 0.0);
   SetIndexLabel(5, "Пробой ВНИЗ");

   return(0);
}


//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit(){return(0);}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0)  return(-1);
   if(counted_bars > 0)   counted_bars--;
   int limit = Bars - counted_bars;
   if(counted_bars==0) limit-=1+MathMax(LeftBars,RightBars);

   for(int i = limit-1; i >= 0; i--)
   {
      LineUpBuffer1[i] = isFractalUp(i, LeftBars, RightBars,limit);
      if(LineUpBuffer1[i] == 0)
         LineUpBuffer1[i] = LineUpBuffer1[i+1];
      else
         ArrowUpBuffer3[i] = LineUpBuffer1[i];
      
      LineDownBuffer2[i] = isFractalDown(i, LeftBars, RightBars,limit);
      if(LineDownBuffer2[i] == 0)
         LineDownBuffer2[i] = LineDownBuffer2[i+1];
      else
         ArrowDownBuffer4[i] = LineDownBuffer2[i];
         
      if(Close[i] < LineDownBuffer2[i] && Close[i+1] >= LineDownBuffer2[i+1])
         ArrowBreakDownBuffer6[i] = Close[i];
   }
   //LineUpBuffer1[-1] = LineUpBuffer1[0];
   //LineDownBuffer2[-1] = LineDownBuffer2[0];
   return(0);
}





double isFractalUp(int index, int lBars, int rBars, int maxind)
{
   int left = lBars, right = rBars;
   double max = High[index]; //Принимаем за максимум значение Хая исследуемого бара
   for(int i = index - right; i <= (index + left); i++)
   {
     if (i<0 || i>maxind) return(0);
      if(!(High[i] > 0.0))return(0);
      if(max < High[i] && i != index)
      {
         if(max < High[i])  return(0);
         if(MathAbs(i - index) > 1) return(0);
      }
   }
   return(max);
}




double isFractalDown(int index, int lBars, int rBars, int maxind)
{
   int left = lBars, right = rBars;
   double min = Low[index], test;
   for(int i = index - right; i <= (index + left); i++)
   {
      if (i<0 || i>maxind) return(0);
      if(!(Low[i] > 0.0))return(0);
      //if(min >= Low[i] && i != index)
      if(min > Low[i] && i != index)
      {
         if(min > Low[i])
            return(0);

         if(MathAbs(i - index) > 1)
            return(0);
      }

   }
   return(min);
}