
using System;
using System.Collections.Generic;
using System.Text;

using FoxPro.CodeDom;

namespace VFPX.FoxProIntegration.CodeDomCodeModel {
    internal class StringMerger : IMergeDestination {
        private bool hasMerged = false;
        private List<string> buffer;

        public StringMerger(string initialText) {
            if (string.IsNullOrEmpty(initialText)) {
                buffer = new List<string>();
            } else {
                string text = initialText.Replace(Environment.NewLine, "\r");
                buffer = new List<string>(text.Split('\r'));
            }
        }

        /// <summary>
        /// Returns the text in the buffer starting from a specific line.
        /// </summary>
        internal string GetTextFromLine(int line) {
            if (line < 0) {
                throw new System.ArgumentOutOfRangeException();
            }
            StringBuilder returnText = new StringBuilder();
            for (int i = line; i < buffer.Count; ++i) {
                returnText.AppendLine(buffer[i]);
            }
            return returnText.ToString();
        }

        #region IMergeDestination members
        public void InsertRange(int start, IList<string> lines) {
            if ((null == lines) || (lines.Count == 0)) {
                hasMerged = true;
                return;
            }

            // Check the parameters.
            if (start < 0) {
                throw new System.ArgumentOutOfRangeException();
            }

            int startLine = start;
            if (startLine > buffer.Count) {
                startLine = buffer.Count;
            }
            buffer.InsertRange(startLine, lines);
            hasMerged = true;
        }

        public void RemoveRange(int start, int count) {
            // Check the parameters.
            if (start < 0) {
                throw new System.ArgumentOutOfRangeException();
            }

            for (int i=0; (i < count) && (start < buffer.Count); ++i) {
                buffer.RemoveAt(start);
            }
            hasMerged = true;
        }

        public int LineCount {
            get { return buffer.Count; }
        }

        public bool HasMerged {
            get { return hasMerged; }
        }

        public string FinalText {
            get { 
                // return back modified text
                hasMerged = false;
                StringBuilder builder = new StringBuilder();
                foreach (string line in buffer) {
                    builder.AppendLine(line);
                }
                return builder.ToString();
            }
        }
        #endregion
    }
}
