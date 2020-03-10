//+------------------------------------------------------------------+
//|                                                     MaSarADX.mq5 |
//|                                                           MauBra |
//+------------------------------------------------------------------+
#property copyright "MauBra"
#property link      "https://login.mql5.com/en/users/almaro"

#define MAGICMA  20050610

#include <Trade\Trade.mqh>

input int    ADX_Period=14;              // ADX Period
input double Lots               = 0.1;   // Lots
input double MaximumRisk        = 0.002; // Maximum Risk in percentage
input double DecreaseFactor     = 3;     // Descrease factor
input int    MovingPeriod       = 100;   // Moving Average period
input int    MovingShift        = 0;     // Moving Average shift
//---
int   ExtMAHandle=0;
int   ExtADXHandle=0;
int   ExtSARHandle=0;
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(void)
  {
   double price=0.0;
   double margin=0.0;
//--- select lot size
   if(!SymbolInfoDouble(_Symbol,SYMBOL_ASK,price))
      return(0.0);
   if(!OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,1.0,price,margin))
      return(0.0);
   if(margin<=0.0)
      return(0.0);

   double lot=NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)*MaximumRisk/margin,2);
//--- calculate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int    orders=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of losses orders without a break

      for(int i=orders-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
           {
            Print("HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=_Symbol)
            continue;
         //--- check profit
         double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(profit>0.0)
            break;
         if(profit<0.0)
            losses++;
        }
      //---
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- normalize and check limits
   double stepvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   lot=stepvol*NormalizeDouble(lot/stepvol,0);

   double minvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(lot<minvol)
      lot=minvol;

   double maxvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open position conditions                               |
//+------------------------------------------------------------------+
void CheckForOpen(void)
  {
   MqlRates rt[2];
//--- go trading only for first ticks of new bar
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2)
     {
      Print("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   if(rt[1].tick_volume>1)
      return;
//--- get current Moving Average 
   double   ma[1],adx_main[1],adx_plus[1],adx_minus[1],sar[1];
   if(CopyBuffer(ExtMAHandle,0,0,1,ma)!=1)
     {
      Print("CopyBuffer from iMA failed, no data");
      return;
     }
//--- copy data from adx main line
   if(CopyBuffer(ExtADXHandle,MAIN_LINE,0,1,adx_main)!=1)
     {
      Print("CopyBuffer from ADX main line failed, no data");
      return;
     }
//--- copy data from adx+ line
   if(CopyBuffer(ExtADXHandle,PLUSDI_LINE,0,1,adx_plus)!=1)
     {
      Print("CopyBuffer from ADX plus line failed, no data");
      return;
     }
//--- copy data from adx- main line
   if(CopyBuffer(ExtADXHandle,MINUSDI_LINE,0,1,adx_minus)!=1)
     {
      Print("CopyBuffer from ADX minus line failed, no data");
      return;
     }
//--- copy data from sar    
   if(CopyBuffer(ExtSARHandle,0,0,1,sar)!=1)
     {
      Print("CopyBuffer from SAR failed, no data");
      return;
     }
//--- check signals
   ENUM_ORDER_TYPE signal=WRONG_VALUE;
//---- sell conditions
   if((rt[0].close<ma[0]) && (adx_plus[0]<=adx_minus[0]) && (rt[0].close<sar[0]))
     {
      signal=ORDER_TYPE_SELL;    // sell conditions
     }
//---- buy conditions
   if((rt[0].close>ma[0]) && (adx_plus[0]>=adx_minus[0]) && (rt[0].close>sar[0]))
     {
      signal=ORDER_TYPE_BUY;  // buy conditions
     }

//--- additional checking
   if(signal!=WRONG_VALUE)
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         if(Bars(_Symbol,_Period)>100)
           {
            CTrade trade;
            trade.SetExpertMagicNumber(MAGICMA);
            trade.PositionOpen(_Symbol,signal,TradeSizeOptimized(),
                               SymbolInfoDouble(_Symbol,signal==ORDER_TYPE_SELL ? SYMBOL_BID:SYMBOL_ASK),
                               0,0);
           }
//---
  }
//+------------------------------------------------------------------+
//| Check for close position conditions                              |
//+------------------------------------------------------------------+
void CheckForClose(void)
  {
   MqlRates rt[2];
//--- go trading only for first ticks of new bar
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2)
     {
      Print("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   if(rt[1].tick_volume>1)
      return;
//---
   double sar[1];
//--- get current SAR
   if(CopyBuffer(ExtSARHandle,0,0,1,sar)!=1)
     {
      Print("CopyBuffer from SAR failed, no data");
      return;
     }
//--- positions already selected before
   bool signal=false;
   long type=PositionGetInteger(POSITION_TYPE);
   
//--- check magic
   long magic=PositionGetInteger(POSITION_MAGIC);
   if (magic!=MAGICMA) return;
   
//---
   if(type==(long)POSITION_TYPE_BUY && rt[0].close<sar[0])
      signal=true;
   if(type==(long)POSITION_TYPE_SELL && rt[0].close>sar[0])
      signal=true;
//--- additional checking
   if(signal)
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         if(Bars(_Symbol,_Period)>100)
           {
            CTrade trade;
            trade.PositionClose(_Symbol,3);
           }
//---
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//---
   ExtMAHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE);
   if(ExtMAHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
//---     
   ExtADXHandle=iADX(_Symbol,_Period,ADX_Period);
   if(ExtADXHandle==INVALID_HANDLE)
     {
      printf("Error creating ADX indicator");
      return(INIT_FAILED);
     }
//--
   ExtSARHandle=iSAR(_Symbol,_Period,0.02,0.1);
   if(ExtSARHandle==INVALID_HANDLE)
     {
      printf("Error creating ADX indicator");
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//---
   if(PositionSelect(_Symbol))
      CheckForClose();
   else
      CheckForOpen();
//---
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
