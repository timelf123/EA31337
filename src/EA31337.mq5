//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2021, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+
/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Includes.
#include "include/includes.h"

// EA properties.
#property strict
#property version ea_version
#ifdef __MQL4__
#property description ea_name
#property description ea_desc
#endif
#property link ea_link
#property copyright ea_copy

// Global variables.
EA *ea;

/* EA event handler functions */

/**
 * Initialization function of the expert.
 */
int OnInit() {
  bool _initiated = true;
  PrintFormat("%s v%s (%s) initializing...", ea_name, ea_version, ea_link);
  _initiated &= InitEA();
  _initiated &= InitStrategies();
  if (GetLastError() > 0) {
    ea.Log().Error("Error during initializing!", __FUNCTION_LINE__, Terminal::GetLastErrorText());
  }
  DisplayStartupInfo(true);
  ea.Log().Flush();
  Chart::WindowRedraw();
  if (!_initiated) {
    ea.GetState().Enable(false);
  }
  return (_initiated ? INIT_SUCCEEDED : INIT_FAILED);
}

/**
 * Deinitialization function of the expert.
 */
void OnDeinit(const int reason) { DeinitVars(); }

/**
 * "Tick" event handler function (EA only).
 *
 * Invoked when a new tick for a symbol is received, to the chart of which the Expert Advisor is attached.
 */
void OnTick() {
  EAProcessResult _result = ea.ProcessTick();
  if (_result.stg_processed) {
    if (PrintLogOnChart) {
      Comment("");
      // DisplayInfo();
    }
  }
}

#ifdef __MQL5__
/**
 * "Trade" event handler function (MQL5 only).
 *
 * Invoked when a trade operation is completed on a trade server.
 */
void OnTrade() {}

/**
 * "OnTradeTransaction" event handler function (MQL5 only).
 *
 * Invoked when performing some definite actions on a trade account, its state changes.
 */
void OnTradeTransaction(const MqlTradeTransaction &trans,  // Trade transaction structure.
                        const MqlTradeRequest &request,    // Request structure.
                        const MqlTradeResult &result       // Result structure.
) {}

/**
 * "Timer" event handler function (MQL5 only).
 *
 * Invoked periodically generated by the EA that has activated the timer by the EventSetTimer function.
 * Usually, this function is called by OnInit.
 */
void OnTimer() {}

/**
 * "TesterInit" event handler function (MQL5 only).
 *
 * The start of optimization in the strategy tester before the first optimization pass.
 *
 * Invoked with the start of optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void TesterInit() {}

/**
 * "OnTester" event handler function.
 *
 * Invoked after a history testing of an Expert Advisor on the chosen interval is over.
 * It is called right before the call of OnDeinit().
 *
 * Returns calculated value that is used as the Custom max criterion
 * in the genetic optimization of input parameters.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
// double OnTester() { return 1.0; }

/**
 * "OnTesterPass" event handler function (MQL5 only).
 *
 * Invoked when a frame is received during Expert Advisor optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void OnTesterPass() {}

/**
 * "OnTesterDeinit" event handler function (MQL5 only).
 *
 * Invoked after the end of Expert Advisor optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void OnTesterDeinit() {}

/**
 * "OnBookEvent" event handler function (MQL5 only).
 *
 * Invoked on Depth of Market changes.
 * To pre-subscribe use the MarketBookAdd() function.
 * In order to unsubscribe for a particular symbol, call MarketBookRelease().
 */
void OnBookEvent(const string &symbol) {}

/**
 * "OnBookEvent" event handler function (MQL5 only).
 *
 * Invoked by the client terminal when a user is working with a chart.
 */
void OnChartEvent(const int id,          // Event ID.
                  const long &lparam,    // Parameter of type long event.
                  const double &dparam,  // Parameter of type double event.
                  const string &sparam   // Parameter of type string events.
) {}

// @todo: OnTradeTransaction (https://www.mql5.com/en/docs/basis/function/events).
#endif  // end: __MQL5__

/* Custom EA functions */

/**
 * Display info on the chart.
 */
bool DisplayStartupInfo(bool _startup = false, string sep = "\n") {
  string _output = "";
  ResetLastError();
  if (ea.GetState().IsOptimizationMode() || (ea.GetState().IsTestingMode() && !ea.GetState().IsTestingVisualMode())) {
    // Ignore chart updates when optimizing or testing in non-visual mode.
    return false;
  }
  _output += "ACCOUNT: " + ea.Account().ToString() + sep;
  _output += "EA: " + ea.ToString() + sep;
  _output += "MARKET: " + ea.Market().ToString() + sep;
  _output += "SYMBOL: " + ea.SymbolInfo().ToString() + sep;
  _output += "TERMINAL: " + ea.Terminal().ToString() + sep;
  // Print strategies info.
  /*
  int sid;
  Strategy *_strat;
  _output += "STRATEGIES:" + sep;
  for (sid = 0; sid < ea.strats.GetSize(); sid++) {
    _strat = ((Strategy *)strats.GetByIndex(sid));
    _output += _strat.ToString();
  }
  */
  if (_startup) {
    if (ea.GetState().IsTradeAllowed()) {
      if (!Terminal::HasError()) {
        _output += sep + "Trading is allowed, waiting for new bars...";
      } else {
        _output += sep + "Trading is allowed, but there is some issue...";
        _output += sep + Terminal::GetLastErrorText();
        ea.Log().AddLastError(__FUNCTION_LINE__);
      }
    } else if (Terminal::IsRealtime()) {
      _output += sep + StringFormat(
                           "Error %d: Trading is not allowed for this symbol, please enable automated trading or check "
                           "the settings!",
                           __LINE__);
    } else {
      _output += sep + "Waiting for new bars...";
    }
  }
  Comment(_output);
  return !Terminal::HasError();
}

/**
 * Init EA.
 */
bool InitEA() {
  bool _initiated = ea_auth;
  EAParams ea_params(__FILE__, VerboseLevel);
  ea_params.SetChartInfoFreq(PrintLogOnChart ? 2 : 0);
  ea_params.SetName(ea_name);
  ea_params.SetAuthor(StringFormat("%s (%s)", ea_author, ea_link));
  ea_params.SetDesc(ea_desc);
  ea_params.SetVersion(ea_version);
  ea = new EA(ea_params);
  if (!ea.GetState().IsTradeAllowed()) {
    ea.Log().Error("Trading is not allowed for this symbol, please enable automated trading or check the settings!",
                   __FUNCTION_LINE__);
    _initiated = false;
  }
  return _initiated;
}

/**
 * Init strategies.
 */
bool InitStrategies() {
  bool _res = ea_exists;
  int _magic_step = FINAL_ENUM_TIMEFRAMES_INDEX;
  long _magic_no = EA_MagicNumber;
  ResetLastError();
  // Initialize strategies per timeframe.
  EAStrategyAdd(Strategy_M1, M1B);
  EAStrategyAdd(Strategy_M5, M5B);
  EAStrategyAdd(Strategy_M15, M15B);
  EAStrategyAdd(Strategy_M30, M30B);
  // Update lot size.
  EAPropertySet(STRAT_PROP_LS, EA_LotSize);
#ifdef __advanced__
#ifdef __rider__
  // Init price stop methods for all timeframes.
  if (EA_Stops != 0) {
    Strategy *_strat_stops = ea.GetStrategy(PERIOD_M30, EA_Stops);
    if (!_strat_stops) {
      // @fixme: Load the missing strategy.
    }
    if (_strat_stops) {
      for (DictObjectIterator<ENUM_TIMEFRAMES, DictStruct<long, Ref<Strategy>>> iter_tf = ea.GetStrategies().Begin();
           iter_tf.IsValid(); ++iter_tf) {
        ENUM_TIMEFRAMES _tf = iter_tf.Key();
        for (DictStructIterator<long, Ref<Strategy>> iter = ea.GetStrategiesByTf(_tf).Begin(); iter.IsValid(); ++iter) {
          Strategy *_strat = iter.Value().Ptr();
          _strat.SetStops(_strat_stops, _strat_stops);
        }
      }
    }
  }
  EAPropertySet(STRAT_PROP_PSM, 1);
  EAPropertySet(STRAT_PROP_OCT, EA_OrderCloseTime);
#else
  // Init price stop methods for each timeframe.
  if (EA_Stops_M1 != STRAT_NONE) {
    Strategy *_strat_stops = ea.GetStrategy(PERIOD_M1, EA_Stops_M1);
    if (!_strat_stops) {
      // @fixme: Load the missing strategy.
    }
    if (_strat_stops) {
      for (DictStructIterator<long, Ref<Strategy>> iter = ea.GetStrategiesByTf(PERIOD_M1).Begin(); iter.IsValid();
           ++iter) {
        Strategy *_strat = iter.Value().Ptr();
        _strat.SetStops(_strat_stops, _strat_stops);
      }
    }
  }
  if (EA_Stops_M5 != STRAT_NONE) {
    Strategy *_strat_stops = ea.GetStrategy(PERIOD_M5, EA_Stops_M5);
    if (!_strat_stops) {
      // @fixme: Load the missing strategy.
    }
    if (_strat_stops) {
      for (DictStructIterator<long, Ref<Strategy>> iter = ea.GetStrategiesByTf(PERIOD_M5).Begin(); iter.IsValid();
           ++iter) {
        Strategy *_strat = iter.Value().Ptr();
        _strat.SetStops(_strat_stops, _strat_stops);
      }
    }
  }
  if (EA_Stops_M15 != STRAT_NONE) {
    Strategy *_strat_stops = ea.GetStrategy(PERIOD_M15, EA_Stops_M15);
    if (!_strat_stops) {
      // @fixme: Load the missing strategy.
    }
    if (_strat_stops) {
      for (DictStructIterator<long, Ref<Strategy>> iter = ea.GetStrategiesByTf(PERIOD_M15).Begin(); iter.IsValid();
           ++iter) {
        Strategy *_strat = iter.Value().Ptr();
        _strat.SetStops(_strat_stops, _strat_stops);
      }
    }
  }
  if (EA_Stops_M30 != STRAT_NONE) {
    Strategy *_strat_stops = ea.GetStrategy(PERIOD_M30, EA_Stops_M30);
    if (!_strat_stops) {
      // @fixme: Load the missing strategy.
    }
    if (_strat_stops) {
      for (DictStructIterator<long, Ref<Strategy>> iter = ea.GetStrategiesByTf(PERIOD_M30).Begin(); iter.IsValid();
           ++iter) {
        Strategy *_strat = iter.Value().Ptr();
        _strat.SetStops(_strat_stops, _strat_stops);
      }
    }
  }

  // Update price stop method.
  EAPropertySet(STRAT_PROP_PSM, 1);
  // Update order close times.
  EAPropertySet(STRAT_PROP_OCT, EA_OrderCloseTime_M1, PERIOD_M1);
  EAPropertySet(STRAT_PROP_OCT, EA_OrderCloseTime_M5, PERIOD_M5);
  EAPropertySet(STRAT_PROP_OCT, EA_OrderCloseTime_M15, PERIOD_M15);
  EAPropertySet(STRAT_PROP_OCT, EA_OrderCloseTime_M30, PERIOD_M30);
#endif  // __rider__
#endif  // __advanced__
  _res &= GetLastError() == 0 || GetLastError() == 5053;  // @fixme: error 5053?
  ResetLastError();
  return _res && ea_configured;
}

/**
 * Set property for given EA's strategies.
 */
bool EAPropertySet(ENUM_STRATEGY_PROP_DBL _prop, double _value, int _tfs = 0) {
  MqlParam _aargs[] = {{TYPE_INT}, {TYPE_INT}, {TYPE_INT}, {TYPE_DOUBLE}};
  // Update close method.
  _aargs[0].integer_value = STRAT_ACTION_SET_PROP;
  _aargs[1].integer_value = _tfs;  // Which timeframes (0 - all).
  _aargs[2].integer_value = _prop;
  _aargs[3].double_value = _value;
  return ea.ExecuteAction(EA_ACTION_STRATS_EXE_ACTION, _aargs);
}

/**
 * Set property for given EA's strategies.
 */
bool EAPropertySet(ENUM_STRATEGY_PROP_INT _prop, int _value, int _tfs = 0) {
  MqlParam _aargs[] = {{TYPE_INT}, {TYPE_INT}, {TYPE_INT}, {TYPE_INT}};
  // Update close method.
  _aargs[0].integer_value = STRAT_ACTION_SET_PROP;
  _aargs[1].integer_value = _tfs;  // Which timeframes (0 - all).
  _aargs[2].integer_value = _prop;
  _aargs[3].integer_value = _value;
  return ea.ExecuteAction(EA_ACTION_STRATS_EXE_ACTION, _aargs);
}

/**
 * Adds strategy to the given timeframe.
 */
bool EAStrategyAdd(ENUM_STRATEGY _stg, int _tfs) {
  unsigned int _magic_no = EA_MagicNumber + _stg * FINAL_ENUM_TIMEFRAMES_INDEX;
  switch (_stg) {
    case STRAT_AC:
      return ea.StrategyAdd<Stg_AC>(_tfs, _stg, _magic_no);
    case STRAT_AD:
      return ea.StrategyAdd<Stg_AD>(_tfs, _stg, _magic_no);
    case STRAT_ADX:
      return ea.StrategyAdd<Stg_ADX>(_tfs, _stg, _magic_no);
    case STRAT_ATR:
      return ea.StrategyAdd<Stg_ATR>(_tfs, _stg, _magic_no);
    case STRAT_ALLIGATOR:
      return ea.StrategyAdd<Stg_Alligator>(_tfs, _stg, _magic_no);
    case STRAT_AWESOME:
      return ea.StrategyAdd<Stg_Awesome>(_tfs, _stg, _magic_no);
    case STRAT_BWMFI:
      return ea.StrategyAdd<Stg_BWMFI>(_tfs, _stg, _magic_no);
    case STRAT_BANDS:
      return ea.StrategyAdd<Stg_Bands>(_tfs, _stg, _magic_no);
    case STRAT_BEARS_POWER:
      return ea.StrategyAdd<Stg_BearsPower>(_tfs, _stg, _magic_no);
    case STRAT_BULLS_POWER:
      return ea.StrategyAdd<Stg_BullsPower>(_tfs, _stg, _magic_no);
    case STRAT_CCI:
      return ea.StrategyAdd<Stg_CCI>(_tfs, _stg, _magic_no);
    case STRAT_DEMARKER:
      return ea.StrategyAdd<Stg_DeMarker>(_tfs, _stg, _magic_no);
    // case STRAT_EWO: return ea.StrategyAdd<Stg_ElliottWave>(_tfs, _stg, _magic_no);
    case STRAT_ENVELOPES:
      return ea.StrategyAdd<Stg_Envelopes>(_tfs, _stg, _magic_no);
    case STRAT_FORCE:
      return ea.StrategyAdd<Stg_Force>(_tfs, _stg, _magic_no);
    case STRAT_FRACTALS:
      return ea.StrategyAdd<Stg_Fractals>(_tfs, _stg, _magic_no);
    case STRAT_GATOR:
      return ea.StrategyAdd<Stg_Gator>(_tfs, _stg, _magic_no);
    case STRAT_ICHIMOKU:
      return ea.StrategyAdd<Stg_Ichimoku>(_tfs, _stg, _magic_no);
    case STRAT_MA:
      return ea.StrategyAdd<Stg_MA>(_tfs, _stg, _magic_no);
    case STRAT_MACD:
      return ea.StrategyAdd<Stg_MACD>(_tfs, _stg, _magic_no);
    case STRAT_MFI:
      return ea.StrategyAdd<Stg_MFI>(_tfs, _stg, _magic_no);
    case STRAT_MOMENTUM:
      return ea.StrategyAdd<Stg_Momentum>(_tfs, _stg, _magic_no);
    case STRAT_OBV:
      return ea.StrategyAdd<Stg_OBV>(_tfs, _stg, _magic_no);
    case STRAT_OSMA:
      return ea.StrategyAdd<Stg_OsMA>(_tfs, _stg, _magic_no);
    case STRAT_RSI:
      return ea.StrategyAdd<Stg_RSI>(_tfs, _stg, _magic_no);
    case STRAT_RVI:
      return ea.StrategyAdd<Stg_RVI>(_tfs, _stg, _magic_no);
    case STRAT_SAR:
      return ea.StrategyAdd<Stg_SAR>(_tfs, _stg, _magic_no);
    case STRAT_STDDEV:
      return ea.StrategyAdd<Stg_StdDev>(_tfs, _stg, _magic_no);
    case STRAT_STOCHASTIC:
      return ea.StrategyAdd<Stg_Stochastic>(_tfs, _stg, _magic_no);
    case STRAT_WPR:
      return ea.StrategyAdd<Stg_WPR>(_tfs, _stg, _magic_no);
    case STRAT_ZIGZAG:
      return ea.StrategyAdd<Stg_ZigZag>(_tfs, _stg, _magic_no);
  }
  return _stg == STRAT_NONE;
}

/**
 * Deinitialize global class variables.
 */
void DeinitVars() { Object::Delete(ea); }
