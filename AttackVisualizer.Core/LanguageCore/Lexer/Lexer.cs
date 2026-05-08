using System;
using System.Collections.Generic;
using System.Text;

namespace AttackVisualizer.LanguageCore.Lexer
{
    public class Lexer
    {
        private readonly string _input;
        private int _position;
        private int _line = 1;
        private int _column = 1;

        public Lexer(string input)
        {
            _input = input;
        }

        private char Current => _position >= _input.Length ? '\0' : _input[_position];

        private void Advance()
        {
            if (Current == '\n')
            {
                _line++;
                _column = 1;
            }
            else
            {
                _column++;
            }
            _position++;
        }

        public List<Token> Tokenize()
        {
            var tokens = new List<Token>();

            while (_position < _input.Length)
            {
                if (char.IsWhiteSpace(Current))
                {
                    Advance();
                }
                else if (char.IsLetter(Current) || Current == '_')
                {
                    tokens.Add(ReadIdentifier());
                }
                else if (char.IsDigit(Current))
                {
                    tokens.Add(ReadNumber());
                }
                else if (Current == '"')
                {
                    tokens.Add(ReadString());
                }
                else
                {
                    tokens.Add(ReadOperator());
                }
            }

            tokens.Add(new Token(TokenType.EOF, string.Empty, _line, _column));
            return tokens;
        }

        private Token ReadIdentifier()
        {
            var startCol = _column;
            var sb = new StringBuilder();
            while (char.IsLetterOrDigit(Current) || Current == '_')
            {
                sb.Append(Current);
                Advance();
            }
            return new Token(TokenType.Identifier, sb.ToString(), _line, startCol);
        }

        private Token ReadNumber()
        {
            var startCol = _column;
            var sb = new StringBuilder();
            while (char.IsDigit(Current))
            {
                sb.Append(Current);
                Advance();
            }
            return new Token(TokenType.Number, sb.ToString(), _line, startCol);
        }

        private Token ReadString()
        {
            var startCol = _column;
            Advance(); // skip opening quote
            var sb = new StringBuilder();
            while (Current != '"' && Current != '\0')
            {
                sb.Append(Current);
                Advance();
            }
            if (Current == '"') Advance(); // skip closing quote
            return new Token(TokenType.String, sb.ToString(), _line, startCol);
        }

        private Token ReadOperator()
        {
            var startCol = _column;
            var c = Current;
            Advance();

            return c switch
            {
                '.' => new Token(TokenType.Dot, ".", _line, startCol),
                '(' => new Token(TokenType.LeftParen, "(", _line, startCol),
                ')' => new Token(TokenType.RightParen, ")", _line, startCol),
                ',' => new Token(TokenType.Comma, ",", _line, startCol),
                _ => new Token(TokenType.Unknown, c.ToString(), _line, startCol)
            };
        }
    }
}
