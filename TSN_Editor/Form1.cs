using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace TSN_Editor
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            int size = -1;
            OpenFileDialog openFileDialog1 = new OpenFileDialog();
            openFileDialog1.Filter = "TSN Files (*.tsn)|*.tsn|All Files (*.*)|*.*";
            DialogResult result = openFileDialog1.ShowDialog(); // Show the dialog.
            if (result == DialogResult.OK) // Test result.
            {
                string file = openFileDialog1.FileName;
                try
                {
                    string text = File.ReadAllText(file);
                    size = text.Length;
                }
                catch (IOException)
                {
                }
            }
            richTextBox1.Text = openFileDialog1.FileName;
            Console.WriteLine(size); // <-- Shows file size in debugging mode.
            Console.WriteLine(result); // <-- For debugging use.
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (checkBox1.Checked)
            {
                if (richTextBox3.TextLength < 2)
                {
                    string message = "No script path selected";
                    string title = "Script Path Error";
                    MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                else
                {
                    richTextBox2.Text = "Parse files and Import to Mysql";
                    // run edit_league.py from the path stored in richTextBox3.Text with the argument of import=yes
                    // C to close the window K to leave it open
                    string strCmdPath = richTextBox3.Text;
                    string strCmdText = "/K " + strCmdPath + "\\edit_league.py";
                    System.Diagnostics.Process.Start("CMD.exe", strCmdText);
                }                
            }
            if (!checkBox1.Checked)
            {
                if (richTextBox3.TextLength < 2)
                {
                    string message = "No script path selected";
                    string title = "Script Path Error";
                    MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                else
                {
                    richTextBox2.Text = "Parse files and NO IMPORT";
                    // run edit_league.py from the path stored in richTextBox3.Text with the argument of import=no
                    string strCmdPath = richTextBox3.Text;
                    string strCmdText = "/K " + strCmdPath + "\\edit_league.py";
                    System.Diagnostics.Process.Start("CMD.exe", strCmdText);
                }                
            }

        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {

        }

        private void button6_Click(object sender, EventArgs e)
        {
            FolderBrowserDialog dialog = new FolderBrowserDialog();
            dialog.ShowDialog();
            richTextBox3.Text = dialog.SelectedPath;
        }
    }
}
