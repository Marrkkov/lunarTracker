// Development-only: captures just a window of the isolated Rainmeter process.
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
public static class LunarCapture {
    delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc callback, IntPtr p);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint id);
    [DllImport("user32.dll")] static extern int GetClassName(IntPtr h, StringBuilder text, int max);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out Rect r);
    [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr h, uint message, IntPtr wp, ref CopyData data);
    [StructLayout(LayoutKind.Sequential)] struct CopyData { public IntPtr Tag; public int Size; public IntPtr Data; }
    [StructLayout(LayoutKind.Sequential)] struct Rect { public int Left,Top,Right,Bottom; }
    public static void Bang(uint processId,string command) {
        bool sent=false;
        EnumWindows(delegate(IntPtr h,IntPtr p) {
            uint id; GetWindowThreadProcessId(h,out id);
            var text=new StringBuilder(256); GetClassName(h,text,256);
            if(id!=processId || text.ToString()!="DummyRainWClass") return true;
            var data=new CopyData {Tag=(IntPtr)1,Size=(command.Length+1)*2,Data=Marshal.StringToHGlobalUni(command)};
            try { SendMessage(h,0x4A,IntPtr.Zero,ref data); sent=true; }
            finally { Marshal.FreeHGlobal(data.Data); }
            return false;
        },IntPtr.Zero);
        if(!sent) throw new Exception("Isolated Rainmeter control window not found");
    }
    public static string Capture(uint processId, string output) {
        string result="No skin window found";
        EnumWindows(delegate(IntPtr h,IntPtr p) {
            uint id; GetWindowThreadProcessId(h,out id);
            if(id!=processId) return true;
            var text=new StringBuilder(256); GetClassName(h,text,256);
            Rect r; GetWindowRect(h,out r);
            if(text.ToString()!="RainmeterMeterWindow" || r.Right-r.Left<100) return true;
            using(var b=new Bitmap(r.Right-r.Left,r.Bottom-r.Top,PixelFormat.Format32bppArgb)) {
                using(var g=Graphics.FromImage(b)) {
                    var dc=g.GetHdc(); bool ok=PrintWindow(h,dc,2); g.ReleaseHdc(dc);
                    if(!ok) throw new Exception("PrintWindow failed");
                }
                b.Save(output,ImageFormat.Png);
            }
            result=(r.Right-r.Left)+"x"+(r.Bottom-r.Top)+" -> "+output;
            return false;
        },IntPtr.Zero);
        return result;
    }
}
