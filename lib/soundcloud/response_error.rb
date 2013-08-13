class Soundcloud
  class ResponseError < HTTParty::ResponseError
    def message
      error = response.parsed_response['error'] || response.parsed_response['errors']['error']
      "HTTP status: #{StatusCodes.interpret_status(response.code)} Error: #{error}"
    rescue
      "HTTP status: #{StatusCodes.interpret_status(response.code)}"
    end

    module StatusCodes
      STATUS_CODES = {
        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Request Entity Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",

        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        507 => "Insufficient Storage",
        510 => "Not Extended"
      }

      def self.interpret_status(status)
        "#{status} #{STATUS_CODES[status.to_i]}".strip
      end
    end
  end
end
