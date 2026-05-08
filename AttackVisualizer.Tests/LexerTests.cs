using AttackVisualizer.LanguageCore.Lexer;

namespace AttackVisualizer.Tests
{
    public class LexerTests
    {
        [Fact]
        public void TestTokenizeBasicCommand()
        {
            var input = "worker.move(2, 3)";
            var lexer = new Lexer(input);
            var tokens = lexer.Tokenize();

            Assert.Equal(9, tokens.Count);
            Assert.Equal(TokenType.Identifier, tokens[0].Type);
            Assert.Equal("worker", tokens[0].Value);
            Assert.Equal(TokenType.Dot, tokens[1].Type);
            Assert.Equal(TokenType.Identifier, tokens[2].Type);
            Assert.Equal("move", tokens[2].Value);
            Assert.Equal(TokenType.LeftParen, tokens[3].Type);
            Assert.Equal(TokenType.Number, tokens[4].Type);
            Assert.Equal("2", tokens[4].Value);
            Assert.Equal(TokenType.Comma, tokens[5].Type);
            Assert.Equal(TokenType.Number, tokens[6].Type);
            Assert.Equal("3", tokens[6].Value);
            Assert.Equal(TokenType.RightParen, tokens[7].Type);
            Assert.Equal(TokenType.EOF, tokens[8].Type);
        }

        [Fact]
        public void TestTokenizeString()
        {
            var input = "gather(\"wood\")";
            var lexer = new Lexer(input);
            var tokens = lexer.Tokenize();

            Assert.Equal(5, tokens.Count);
            Assert.Equal(TokenType.Identifier, tokens[0].Type);
            Assert.Equal(TokenType.LeftParen, tokens[1].Type);
            Assert.Equal(TokenType.String, tokens[2].Type);
            Assert.Equal("wood", tokens[2].Value);
            Assert.Equal(TokenType.RightParen, tokens[3].Type);
            Assert.Equal(TokenType.EOF, tokens[4].Type);
        }

        [Fact]
        public void TestTokenizeMultipleLines()
        {
            var input = "worker.move(1,1)\nworker.gather()";
            var lexer = new Lexer(input);
            var tokens = lexer.Tokenize();

            // Line 1: worker(0) .(1) move(2) ((3) 1(4) ,(5) 1(6) )(7)
            // Line 2: worker(8) .(9) gather(10) ((11) )(12)
            // EOF(13)

            Assert.Equal(14, tokens.Count);
            Assert.Equal(2, tokens[8].Line);
            Assert.Equal(1, tokens[8].Column);
            Assert.Equal("worker", tokens[8].Value);
        }
    }
}
