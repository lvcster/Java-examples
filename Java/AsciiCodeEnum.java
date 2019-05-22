	enum AsciiCodeEnum {
		   
	   EXCLAMATION_MARK(33, '!', "Exclamation mark"),
	   QUOTATIONB_MARK(34, '"', "Quotation mark, or Quotes"),
	   NUMBER_SIGN(35, '#', "Number sign"),
	   DOLLAR_SIGN(36, '$', "Dollar sign"),
	   PERCENT_SIGN(37, '%', "Percent sign"),
	   AMPERSAND(38, '&', "Ampersand"),
	   APOSTROPHE(39, '\'', "Apostrophe"),
	   ROUND_OPEN_BRACKET(40, '(', "round open bracket or parentheses"),
	   ROUND_CLOSE_BRACKET(41, ')', "round close bracket or parentheses"),
	   ASTERISK(42, '*', "Asterisk"),
	   PLUS_SIGN(43, '+', "Plus sign");

		private int code;
		private char symbol;
		private String description;

		AsciiCodeEnum(int code, char symbol, String description) {

			this.code = code;
			this.symbol = symbol;
			this.description = description;

		}

		public int getCode() {
			return code;
		}

		public char getSymbol() {
			return symbol;
		}

		public String getDescription() {
			return description;
		}

	}