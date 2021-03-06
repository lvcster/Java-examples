//+------------------------------------------------------------------+
//|      PhD_HalfTrend_TNTF.mq4                                       |
//|      Copyright 2017, PhD Systems                                 |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 8
#property indicator_buffers 6
#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Red
#property indicator_color5 Green
#property indicator_color6 Red

double hour_up_buffer[], hour_down_buffer[],

four_hour_up_buffer[], four_hour_down_buffer[],

day_up_buffer[], day_down_buffer[];

void init() {
   
   IndicatorShortName("PhD indicator");
   
   //--------------------------------------------------------------------
   SetIndexBuffer(0, hour_up_buffer);
   SetIndexStyle(0, DRAW_ARROW, STYLE_DOT, 1);
   //SetIndexArrow(0, 110);
   
   SetIndexBuffer(1, hour_down_buffer);
   SetIndexStyle(1, DRAW_ARROW, STYLE_DOT, 1);
   //SetIndexArrow(1, 110);   

   //--------------------------------------------------------------------
   SetIndexBuffer(2,four_hour_up_buffer);
   SetIndexStyle(2,DRAW_ARROW, STYLE_DOT, 1);
   
   SetIndexBuffer(3,four_hour_down_buffer);
   SetIndexStyle(3,DRAW_ARROW, STYLE_DOT, 1);   

   //--------------------------------------------------------------------
   SetIndexBuffer(4,day_up_buffer);
   SetIndexStyle(4,DRAW_ARROW, STYLE_DOT, 1);
   
   SetIndexBuffer(5,day_down_buffer);
   SetIndexStyle(5,DRAW_ARROW, STYLE_DOT, 1);   
}

void start() {
  
   int i = Bars-IndicatorCounted()-1;           
   while( i >= 0) {
   
      //1 Hour Timeframe
      drawHourTrends(i);
      
      //4 Hour Timeframe
      int fourHourShift = iBarShift(Symbol(), PERIOD_H4, Time[i], false);
      drawFourHourTrends(fourHourShift);
      
      //Day Timeframe
      int dayShift = iBarShift(Symbol(), PERIOD_D1, Time[i], false);      
      //drawDayTrends(dayShift);

      i--;
   }   
     
}

void drawHourTrends(int barIndex) {

   double bullishPhDHalfTrend = NormalizeDouble(iCustom(Symbol(), PERIOD_H1, "PhD_HalfTrend", 0, barIndex), Digits); 
   double bearishPhDHalfTrend = NormalizeDouble(iCustom(Symbol(), PERIOD_H1, "PhD_HalfTrend", 1, barIndex), Digits);   

   if( bullishPhDHalfTrend != 0) {
      
      hour_up_buffer[barIndex] = 5;
      hour_down_buffer[barIndex] = EMPTY_VALUE;
      //four_hour_up_buffer[i] = 2;
      //day_buffer[i]=2.5;
   }
   else if( bearishPhDHalfTrend != 0) {
      hour_down_buffer[barIndex] = 5;
      hour_up_buffer[barIndex] = EMPTY_VALUE;
   }   

}

void drawFourHourTrends(int barIndex) {

   double bullishPhDHalfTrend = NormalizeDouble(iCustom(Symbol(), PERIOD_H4, "PhD_HalfTrend", 0, barIndex), Digits); 
   double bearishPhDHalfTrend = NormalizeDouble(iCustom(Symbol(), PERIOD_H4, "PhD_HalfTrend", 1, barIndex), Digits);   

   if( bullishPhDHalfTrend != 0) {
      
      four_hour_up_buffer[barIndex] = 3;
      four_hour_down_buffer[barIndex] = EMPTY_VALUE;
      //four_hour_up_buffer[i] = 2;
      //day_buffer[i]=2.5;
   }
   else if( bearishPhDHalfTrend != 0) {
      four_hour_down_buffer[barIndex] = 3;
      four_hour_up_buffer[barIndex] = EMPTY_VALUE;
   }   

}   

void drawDayTrends(int barIndex) {

   double bullishPhDHalfTrend = NormalizeDouble(iCustom(Symbol(), PERIOD_D1, "PhD_HalfTrend", 0, barIndex), Digits); 
   double bearishPhDHalfTrend = NormalizeDouble(iCustom(Symbol(), PERIOD_D1, "PhD_HalfTrend", 1, barIndex), Digits);   

   if( bullishPhDHalfTrend != 0) {
      
      day_up_buffer[barIndex] = 1;
      day_down_buffer[barIndex] = EMPTY_VALUE;
      //four_hour_up_buffer[i] = 2;
      //day_buffer[i]=2.5;
   }
   else if( bearishPhDHalfTrend != 0) {
      day_down_buffer[barIndex] = 1;
      day_up_buffer[barIndex] = EMPTY_VALUE;
   }   

}