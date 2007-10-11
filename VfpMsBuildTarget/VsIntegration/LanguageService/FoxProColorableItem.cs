
using System;
using Microsoft.VisualStudio.TextManager.Interop;

namespace VFPX.FoxProIntegration.FoxProLanguageService
{
    public class FoxProColorableItem : IVsColorableItem {

        private string displayName;
        private COLORINDEX background;
        private COLORINDEX foreground;

        public FoxProColorableItem(string displayName, COLORINDEX foreground, COLORINDEX background) {
            this.displayName = displayName;
            this.background = background;
            this.foreground = foreground;
        }

        #region IVsColorableItem Members

        public int GetDefaultColors(COLORINDEX[] piForeground, COLORINDEX[] piBackground) {
            if (null == piForeground) {
                throw new ArgumentNullException("piForeground");
            }
            if (0 == piForeground.Length) {
                throw new ArgumentOutOfRangeException("piForeground");
            }
            piForeground[0] = foreground;

            if (null == piBackground) {
                throw new ArgumentNullException("piBackground");
            }
            if (0 == piBackground.Length) {
                throw new ArgumentOutOfRangeException("piBackground");
            }
            piBackground[0] = background;

            return Microsoft.VisualStudio.VSConstants.S_OK;
        }

        public int GetDefaultFontFlags(out uint pdwFontFlags) {
            pdwFontFlags = 0;
            return Microsoft.VisualStudio.VSConstants.S_OK;
        }

        public int GetDisplayName(out string pbstrName) {
            pbstrName = displayName;
            return Microsoft.VisualStudio.VSConstants.S_OK;
        }

        #endregion
    }
}
