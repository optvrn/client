import '../utils/utils.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:source_gen/source_gen.dart';
import '../parsed_info/parsed_info.dart';

Req _parseReq(String httpMethod, DartObject annot, MethodElement method) {
  final reader = ConstantReader(annot);
  String path = reader.read('path').stringValue;
  var varPathSegs = <String>[];
  print(path);
  if (path != null)
    varPathSegs = path
        .split('/')
        .where((p) => p.startsWith(':'))
        .map((p) => p.substring(1))
        .toList();

  final pathParams = Set<String>();

  final query = <String, String>{};
  final headers = <String, String>{};

  for (ParameterElement pe in method.parameters) {
    if (varPathSegs.contains(pe.displayName)) pathParams.add(pe.displayName);

    {
      DartObject qp = isQueryParam.firstAnnotationOfExact(pe);
      if (qp != null) {
        query[pe.displayName] =
            qp.getField('alias').toStringValue() ?? pe.displayName;
      }
    }

    {
      DartObject hp = isHeader.firstAnnotationOfExact(pe);
      if (hp != null) {
        headers[pe.displayName] =
            hp.getField('alias').toStringValue() ?? pe.displayName;
      }
    }
  }

  return Req(httpMethod, method,
      path: path, pathParams: pathParams, query: query, headers: headers);
}

WriteInfo parse(ClassElement element, ConstantReader annotation) {
  final reqs = <Req>[];

  for (MethodElement me in element.methods) {
    DartObject reqOb = isReq.firstAnnotationOf(me);

    if (isGetReq.isAssignableFromType(reqOb.type)) {
      reqs.add(_parseReq('get', reqOb, me));
    } else if (isPostReq.isAssignableFromType(reqOb.type)) {
      reqs.add(_parseReq('post', reqOb, me));
    } else if (isPutReq.isAssignableFromType(reqOb.type)) {
      reqs.add(_parseReq('put', reqOb, me));
    } else if (isDeleteReq.isAssignableFromType(reqOb.type)) {
      reqs.add(_parseReq('delete', reqOb, me));
    } else if (isHeadReq.isAssignableFromType(reqOb.type)) {
      reqs.add(_parseReq('head', reqOb, me));
    } else if (isPatchReq.isAssignableFromType(reqOb.type)) {
      reqs.add(_parseReq('patch', reqOb, me));
    }
  }

  return WriteInfo(element.displayName, reqs);
}
