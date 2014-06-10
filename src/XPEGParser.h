#import <PEGKit/PKParser.h>

enum {
    XPEG_TOKEN_KIND_FILE = 14,
    XPEG_TOKEN_KIND_GE_SYM,
    XPEG_TOKEN_KIND_PIPE,
    XPEG_TOKEN_KIND_PRECEDINGSIBLING,
    XPEG_TOKEN_KIND_TRUE,
    XPEG_TOKEN_KIND_PARENT,
    XPEG_TOKEN_KIND_ATTR,
    XPEG_TOKEN_KIND_MOD,
    XPEG_TOKEN_KIND_NOT_EQUAL,
    XPEG_TOKEN_KIND_TEXT,
    XPEG_TOKEN_KIND_SELF,
    XPEG_TOKEN_KIND_COMMENT,
    XPEG_TOKEN_KIND_FOLDER,
    XPEG_TOKEN_KIND_COLON,
    XPEG_TOKEN_KIND_CHILD,
    XPEG_TOKEN_KIND_DIV,
    XPEG_TOKEN_KIND_PRECEDING,
    XPEG_TOKEN_KIND_DOLLAR,
    XPEG_TOKEN_KIND_LT_SYM,
    XPEG_TOKEN_KIND_FOLLOWINGSIBLING,
    XPEG_TOKEN_KIND_DESCENDANT,
    XPEG_TOKEN_KIND_EQUALS,
    XPEG_TOKEN_KIND_FOLLOWING,
    XPEG_TOKEN_KIND_DOT_DOT,
    XPEG_TOKEN_KIND_GT_SYM,
    XPEG_TOKEN_KIND_DOUBLE_COLON,
    XPEG_TOKEN_KIND_NAMESPACE,
    XPEG_TOKEN_KIND_NODE,
    XPEG_TOKEN_KIND_OPEN_PAREN,
    XPEG_TOKEN_KIND_ABBREVIATEDAXIS,
    XPEG_TOKEN_KIND_CLOSE_PAREN,
    XPEG_TOKEN_KIND_DOUBLE_SLASH,
    XPEG_TOKEN_KIND_MULTIPLYOPERATOR,
    XPEG_TOKEN_KIND_OR,
    XPEG_TOKEN_KIND_PLUS,
    XPEG_TOKEN_KIND_PROCESSINGINSTRUCTION,
    XPEG_TOKEN_KIND_OPEN_BRACKET,
    XPEG_TOKEN_KIND_COMMA,
    XPEG_TOKEN_KIND_AND,
    XPEG_TOKEN_KIND_MINUS,
    XPEG_TOKEN_KIND_ANCESTOR,
    XPEG_TOKEN_KIND_DOT,
    XPEG_TOKEN_KIND_CLOSE_BRACKET,
    XPEG_TOKEN_KIND_DESCENDANTORSELF,
    XPEG_TOKEN_KIND_FORWARD_SLASH,
    XPEG_TOKEN_KIND_FALSE,
    XPEG_TOKEN_KIND_LE_SYM,
    XPEG_TOKEN_KIND_ANCESTORORSELF,
};

@interface XPEGParser : PKParser

@end

