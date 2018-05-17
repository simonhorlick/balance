import 'dart:async';
import 'dart:typed_data';

import 'package:balance/generated/vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.pb.dart';
import 'package:flutter/services.dart';

const MethodChannel _kChannel = const MethodChannel('rpc');

const EventChannel _kEventChannel =
    const EventChannel('plugins.flutter.io/charging');

class LndClient {
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

  static Future<Invoice> lookupInvoice(PaymentHash request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('LookupInvoice', <String, dynamic>{
      'req': serialised,
    });
    return Invoice.create()..mergeFromBuffer(result);
  }

  static Future<AddInvoiceResponse> addInvoice(Invoice request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('AddInvoice', <String, dynamic>{
      'req': serialised,
    });
    return AddInvoiceResponse.create()..mergeFromBuffer(result);
  }

  static Future<ConnectPeerResponse> connectPeer(
      ConnectPeerRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('ConnectPeer', <String, dynamic>{
      'req': serialised,
    });
    return ConnectPeerResponse.create()..mergeFromBuffer(result);
  }

  static Future<PendingChannelsResponse> pendingChannels(
      PendingChannelsRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('PendingChannels', <String, dynamic>{
      'req': serialised,
    });
    return PendingChannelsResponse.create()..mergeFromBuffer(result);
  }

  static Future<ListChannelsResponse> listChannels(
      ListChannelsRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('ListChannels', <String, dynamic>{
      'req': serialised,
    });
    return ListChannelsResponse.create()..mergeFromBuffer(result);
  }

  static Future<NetworkInfo> getNetworkInfo(NetworkInfoRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('GetNetworkInfo', <String, dynamic>{
      'req': serialised,
    });
    return NetworkInfo.create()..mergeFromBuffer(result);
  }

  static Future<TransactionDetails> getTransactions(
      GetTransactionsRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('GetTransactions', <String, dynamic>{
      'req': serialised,
    });
    return TransactionDetails.create()..mergeFromBuffer(result);
  }

  static Future<NewAddressResponse> newAddress(
      NewAddressRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('NewAddress', <String, dynamic>{
      'req': serialised,
    });
    return NewAddressResponse.create()..mergeFromBuffer(result);
  }

  static Future<PayReq> decodePayReq(PayReqString request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('DecodePayReq', <String, dynamic>{
      'req': serialised,
    });
    return PayReq.create()..mergeFromBuffer(result);
  }

  static Future<SendResponse> sendPaymentSync(SendRequest request) async {
    var serialised = request.writeToBuffer();
    final Uint8List result =
        await _kChannel.invokeMethod('SendPaymentSync', <String, dynamic>{
      'req': serialised,
    });
    return SendResponse.create()..mergeFromBuffer(result);
  }

  static Future<String> start() async {
    final Uint8List result = await _kChannel.invokeMethod('Start');
    return result.toString();
  }
}
