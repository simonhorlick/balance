import 'dart:async';
import 'dart:typed_data';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pb.dart';
import 'package:flutter/services.dart';

const MethodChannel _kChannel = const MethodChannel('rpc');

const EventChannel _kEventChannel =
    const EventChannel('plugins.flutter.io/charging');

class LndClient {
  static Future<GetInfoResponse> getInfo(GetInfoRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('GetInfo', <String, dynamic>{
      'req': serialised,
    });
    return GetInfoResponse.create()..mergeFromBuffer(result);
  }

  static Future<WalletBalanceResponse> walletBalance(
      WalletBalanceRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('WalletBalance', <String, dynamic>{
      'req': serialised,
    });
    return WalletBalanceResponse.create()..mergeFromBuffer(result);
  }

  static Future<ChannelBalanceResponse> channelBalance(
      ChannelBalanceRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('ChannelBalance', <String, dynamic>{
      'req': serialised,
    });
    return ChannelBalanceResponse.create()..mergeFromBuffer(result);
  }

  static Future<ListPaymentsResponse> listPayments(
      ListPaymentsRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('ListPayments', <String, dynamic>{
      'req': serialised,
    });
    return ListPaymentsResponse.create()..mergeFromBuffer(result);
  }

  static Future<ListInvoiceResponse> listInvoices(
      ListInvoiceRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('ListInvoices', <String, dynamic>{
      'req': serialised,
    });
    return ListInvoiceResponse.create()..mergeFromBuffer(result);
  }

  static Stream<Transaction> subscribeTransactions(
      GetTransactionsRequest request) {
    // To implement streaming calls we assign each call a stream id. We then
    // look at the _kEventChannel for responses, instead of looking at the
    // _kChannel.
    var serialised = request.writeToBuffer();
    _kChannel.invokeMethod('SubscribeTransactions', <String, dynamic>{
      'req': serialised,
      'streamId': 6,
    });

    Stream<Transaction> onBatteryStateChanged = _kEventChannel
        .receiveBroadcastStream()
        .where((dynamic event) => _onlyStream(event, 6))
        .map((dynamic event) => _parseBatteryState(event[1]));

    return onBatteryStateChanged;
  }

  static Transaction _parseBatteryState(Uint8List response) {
    return Transaction.create()..mergeFromBuffer(response);
  }

  static bool _onlyStream(dynamic event, int streamId) {
    print("Got event:");
    print(event);
    return true;
//    return event[0] == streamId;
  }
}
