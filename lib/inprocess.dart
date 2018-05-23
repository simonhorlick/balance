import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';

const MethodChannel _kChannel = const MethodChannel('rpc');

/// Start the in-process LND server.
Future<String> start() async {
  final Uint8List result = await _kChannel.invokeMethod('Start');
  return result.toString();
}

/// Read a grpc certificate from the app bundle.
Future<List<int>> readCertificate() {
  return rootBundle.load('assets/tls.cert').then((cert) {
    List<int> intCert = new List();
    for (int i = 0; i < cert.lengthInBytes; i++) {
      intCert.add(cert.getUint8(i));
    }
    return intCert;
  });
}

/// An InProcCall dispatches an rpc to the in-process LND server.
class InProcCall<Q, R> extends ClientCall<Q, R> {
  Stream<Q> requests;
  ClientMethod<Q, R> method;

  InProcCall(ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options)
      : super(method, requests, options) {
    this.requests = requests;
    this.method = method;
  }

  @override
  Stream<R> get response {
    return requests.asyncMap((request) async {
      var serialised = method.requestSerializer(request);
      final Uint8List result =
          await _kChannel.invokeMethod(method.path, <String, dynamic>{
        'req': serialised,
      });
      return method.responseDeserializer(result);
    });
  }
}

class InProcChannel extends ClientChannel {
  InProcChannel() : super("");

  ClientCall<Q, R> createCall<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) {
    final call = new InProcCall(method, requests, options);
    return call;
  }
}
