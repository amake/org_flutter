typedef OrgErrorHandler = void Function(dynamic);

sealed class OrgError implements Exception {
  const OrgError(this.message);

  final String message;
}

class OrgParserError extends OrgError {
  const OrgParserError(super.message, this.result);

  final dynamic result;
}

class OrgExecutionError extends OrgError {
  const OrgExecutionError(super.message, this.code, this.cause);

  final String code;
  final dynamic cause;
}

class OrgTimeoutError extends OrgError {
  const OrgTimeoutError(super.message, this.code, this.timeLimit);

  final String code;
  final Duration timeLimit;
}

class OrgArgumentError extends OrgError {
  const OrgArgumentError(super.message, this.item);

  final dynamic item;
}
